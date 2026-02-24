import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_logger.dart';
import '../data/services/revenuecat_service.dart';

class PremiumStatus {
  const PremiumStatus({
    required this.isPremium,
    required this.isTrialActive,
    required this.trialDaysRemaining,
  });

  final bool isPremium;
  final bool isTrialActive;
  final int trialDaysRemaining;

  bool get hasAccess => isPremium || isTrialActive;
}

class PremiumController extends StateNotifier<PremiumStatus> {
  PremiumController(this._service, this._client)
      : super(const PremiumStatus(
          isPremium: false,
          isTrialActive: false,
          trialDaysRemaining: 0,
        )) {
    _init();
  }

  /// Trial duration (3 days) starting from account creation.
  static const Duration trialDuration = Duration(days: 3);

  final RevenueCatService _service;
  final SupabaseClient _client;

  StreamSubscription<CustomerInfo>? _customerInfoSub;
  StreamSubscription<AuthState>? _authSub;
  Timer? _trialTimer;

  Future<void> _init() async {
    // Keep status fresh on app launch and whenever the auth session changes.
    _authSub = _client.auth.onAuthStateChange.listen((_) {
      unawaited(_updateStatus());
    });

    if (_service.isConfigured) {
      _customerInfoSub = _service.customerInfoStream.listen((_) {
        unawaited(_updateStatus());
      });
    }

    await _updateStatus();
  }

  DateTime? _trialStartUtcFrom(User user) {
    // Trial start date is stored securely in Supabase Auth:
    // auth.users.created_at (exposed via user.createdAt).
    final raw = user.createdAt.trim();
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (error) {
      AppLogger.warn('premium: failed to parse user.createdAt ($raw): $error');
      return null;
    }
  }

  int _trialDaysRemaining({
    required DateTime nowUtc,
    required DateTime trialEndsUtc,
  }) {
    if (!nowUtc.isBefore(trialEndsUtc)) return 0;
    return trialEndsUtc.difference(nowUtc).inDays + 1;
  }

  void _scheduleTrialExpiryCheck(DateTime nowUtc, DateTime trialEndsUtc) {
    _trialTimer?.cancel();
    final delay = trialEndsUtc.difference(nowUtc);
    if (delay.isNegative) return;

    // Add a small buffer so we don't bounce around the boundary.
    _trialTimer = Timer(delay + const Duration(seconds: 1), () {
      unawaited(_updateStatus());
    });
  }

  Future<void> _updateStatus() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        _trialTimer?.cancel();
        state = const PremiumStatus(
          isPremium: false,
          isTrialActive: false,
          trialDaysRemaining: 0,
        );
        return;
      }

      // Check paid subscription.
      final isPremium = _service.isConfigured &&
          ((_service.lastCustomerInfo != null &&
                  _service.isPremiumFrom(_service.lastCustomerInfo!))
              ? true
              : await _service.isPremium());

      // If not premium, allow trial based on account creation time.
      final nowUtc = DateTime.now().toUtc();
      final trialStartUtc = _trialStartUtcFrom(user);
      final trialEndsUtc = trialStartUtc?.add(trialDuration);

      var isTrialActive = false;
      var daysRemaining = 0;
      if (!isPremium && trialEndsUtc != null && nowUtc.isBefore(trialEndsUtc)) {
        isTrialActive = true;
        daysRemaining =
            _trialDaysRemaining(nowUtc: nowUtc, trialEndsUtc: trialEndsUtc);
        _scheduleTrialExpiryCheck(nowUtc, trialEndsUtc);
      } else {
        _trialTimer?.cancel();
      }

      state = PremiumStatus(
        isPremium: isPremium,
        isTrialActive: isTrialActive,
        trialDaysRemaining: daysRemaining,
      );

      AppLogger.info(
        'premium.status: isPremium=$isPremium, trial=$isTrialActive, daysLeft=$daysRemaining',
      );
    } catch (error, stackTrace) {
      AppLogger.error('premium.updateStatus', error, stackTrace);
    }
  }

  @override
  void dispose() {
    _customerInfoSub?.cancel();
    _authSub?.cancel();
    _trialTimer?.cancel();
    super.dispose();
  }
}
