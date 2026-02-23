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
  PremiumController(this._service)
      : super(const PremiumStatus(
          isPremium: false,
          isTrialActive: false,
          trialDaysRemaining: 0,
        )) {
    _init();
  }

  final RevenueCatService _service;
  StreamSubscription<CustomerInfo>? _sub;

  Future<void> _init() async {
    // No key configured: check trial only
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = const PremiumStatus(
          isPremium: false,
          isTrialActive: false,
          trialDaysRemaining: 0,
        );
        return;
      }

      await _updateStatus();

      if (_service.isConfigured) {
        _sub = _service.customerInfoStream.listen((_) {
          _updateStatus();
        });
      }
    } catch (error, stackTrace) {
      AppLogger.error('premium.init', error, stackTrace);
      state = const PremiumStatus(
        isPremium: false,
        isTrialActive: false,
        trialDaysRemaining: 0,
      );
    }
  }

  Future<void> _updateStatus() async {
    try {
      // Check paid subscription
      final isPremium = _service.isConfigured && await _service.isPremium();

      // Check trial status from Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = const PremiumStatus(
          isPremium: false,
          isTrialActive: false,
          trialDaysRemaining: 0,
        );
        return;
      }

      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('trial_ends_at, trial_used')
          .eq('id', user.id)
          .limit(1);

      DateTime? trialEndsAt;
      bool? trialUsed;
      if (profiles.isNotEmpty) {
        trialEndsAt = profiles[0]['trial_ends_at'] != null
            ? DateTime.parse(profiles[0]['trial_ends_at'] as String)
            : null;
        trialUsed = profiles[0]['trial_used'] as bool? ?? false;
      }

      final isTrialActive = !isPremium && _service.isTrialActive(trialEndsAt);
      final daysRemaining = _service.getTrialDaysRemaining(trialEndsAt);

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

  /// Start 7-day trial
  Future<bool> startTrial() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      // Check if trial already used
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('trial_used')
          .eq('id', user.id)
          .limit(1);

      if (profiles.isNotEmpty &&
          (profiles[0]['trial_used'] as bool? ?? false)) {
        AppLogger.warn('premium: trial already used');
        return false;
      }

      // Set trial to end in 7 days
      final trialEndsAt = DateTime.now().add(const Duration(days: 7));

      await Supabase.instance.client.from('profiles').update({
        'trial_ends_at': trialEndsAt.toIso8601String(),
        'trial_used': true,
      }).eq('id', user.id);

      await _updateStatus();
      AppLogger.info('premium: 7-day trial started');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('premium.startTrial', error, stackTrace);
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
