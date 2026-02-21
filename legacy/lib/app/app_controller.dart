import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/models/risk_level.dart';
import '../core/theme/theme_preference.dart';
import '../core/utils/app_logger.dart';
import '../features/onboarding/model/onboarding_profile.dart';
import '../services/discipline_services.dart';
import '../services/store/revenuecat_store.dart';
import 'app_state.dart';

class AppController extends ChangeNotifier {
  static const Duration _syncDebounce = Duration(milliseconds: 350);

  AppController({DisciplineServices? services})
      : services = services ?? DisciplineServices.stub() {
    _bootstrapFromServices();
  }

  final DisciplineServices services;

  AppState _state = AppState.initial();
  AppState get state => _state;
  bool _isHydrating = true;
  bool get isHydrating => _isHydrating;

  Timer? _syncTimer;
  bool _revenueCatListenerAttached = false;
  bool _suppressRevenueCatPremiumSync = false;

  void updateOnboardingProfile(OnboardingProfile profile) {
    _state = _state.copyWith(onboardingProfile: profile);
    _recomputeInsights();
    notifyListeners();
    _scheduleStateSync();
  }

  void completeOnboarding({required bool isPremium}) {
    _state = _state.copyWith(onboardingComplete: true, isPremium: isPremium);
    _recomputeInsights();
    notifyListeners();
    _scheduleStateSync();
  }

  void completeAuth({required bool biometricEnabled}) {
    _state = _state.copyWith(
      isAuthenticated: true,
      biometricEnabled: biometricEnabled,
    );
    _recomputeInsights();
    notifyListeners();
    _finalizeAuthState(biometricEnabled: biometricEnabled);
  }

  Future<void> signOut() async {
    _syncTimer?.cancel();
    _suppressRevenueCatPremiumSync = true;

    final preservedTheme = _state.themePreference;
    _state = AppState.initial().copyWith(themePreference: preservedTheme);
    _recomputeInsights();
    notifyListeners();

    try {
      await services.auth.signOut();
    } catch (error, stackTrace) {
      AppLogger.error('AppController.signOut', error, stackTrace);
    }

    try {
      await RevenueCatStore.instance.configureIfNeeded(appUserId: null);
    } catch (error, stackTrace) {
      AppLogger.error('AppController.signOut.revenueCat', error, stackTrace);
    } finally {
      _suppressRevenueCatPremiumSync = false;
    }
  }

  Future<void> setPremium(bool value) async {
    _state = _state.copyWith(isPremium: value);
    _recomputeInsights();
    notifyListeners();
    try {
      await services.subscription.setPremium(value);
    } catch (error, stackTrace) {
      AppLogger.error('AppController.setPremium', error, stackTrace);
    }
  }

  void setThemePreference(ThemePreference preference) {
    _state = _state.copyWith(themePreference: preference);
    _recomputeInsights();
    notifyListeners();
    _scheduleStateSync();
  }

  void setLockMode(bool enabled) {
    updateOnboardingProfile(
        _state.onboardingProfile.copyWith(lockMode: enabled));
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  void setRiskAlerts(bool enabled) {
    updateOnboardingProfile(
      _state.onboardingProfile.copyWith(riskAlertsEnabled: enabled),
    );
  }

  void logReflection(String text) {
    final normalized = text.trim();
    _state = _state.copyWith(
      lastReflection: normalized.isEmpty ? null : normalized,
    );
    _recomputeInsights();
    notifyListeners();
    _scheduleStateSync();
  }

  void _recomputeInsights() {
    final severity = _state.onboardingProfile.severity;
    final frequency = _state.onboardingProfile.frequency;
    final triggerCount = _state.onboardingProfile.triggers.length;
    final selectedTimeSlots = _state.onboardingProfile.highRiskSlots.length;

    final score = (severity * 0.42) +
        (frequency * 0.26) +
        (math.min(triggerCount, 8) * 0.16) +
        (math.min(selectedTimeSlots / 8.0, 1.0) * 0.16);

    final riskLevel = switch (score) {
      < 3.2 => RiskLevel.low,
      < 6.3 => RiskLevel.medium,
      _ => RiskLevel.high,
    };

    final urgeProbability = (18 + (score * 9)).round().clamp(8, 92);
    final improvement = (42 - (score * 2.5)).round().clamp(6, 54);
    final streakDays = (5 + (improvement / 8).round()).clamp(2, 28);

    _state = _state.copyWith(
      riskLevel: riskLevel,
      urgeProbabilityPercent: urgeProbability,
      improvementPercent: improvement,
      streakDays: streakDays,
      streakProgress: (0.4 + (improvement / 100) * 0.6).clamp(0.08, 0.92),
    );
  }

  Future<void> _bootstrapFromServices() async {
    _isHydrating = true;
    notifyListeners();
    await _hydrateFromServices(
      setAuthenticatedFromSession: true,
      pushIfMissing: true,
      notifyAfter: false,
    );
    await _syncPremiumFromRevenueCat();
    _isHydrating = false;
    notifyListeners();
  }

  Future<void> _finalizeAuthState({required bool biometricEnabled}) async {
    await _hydrateFromServices(
      setAuthenticatedFromSession: true,
      pushIfMissing: true,
      notifyAfter: false,
    );
    await _syncPremiumFromRevenueCat();
    _state = _state.copyWith(
      isAuthenticated: true,
      biometricEnabled: biometricEnabled,
    );
    _recomputeInsights();
    notifyListeners();
    _scheduleStateSync();
  }

  Future<void> _syncPremiumFromRevenueCat() async {
    if (!services.auth.hasActiveSession) return;

    final configured = await RevenueCatStore.instance.configureIfNeeded(
      appUserId: services.auth.currentUserId,
    );
    if (!configured) return;

    if (!_revenueCatListenerAttached) {
      _revenueCatListenerAttached = true;
      RevenueCatStore.instance.addCustomerInfoUpdateListener((customerInfo) {
        if (_suppressRevenueCatPremiumSync) return;
        if (!services.auth.hasActiveSession) return;
        final isPremium = RevenueCatStore.instance.isPremium(customerInfo);
        if (isPremium == _state.isPremium) return;
        unawaited(setPremium(isPremium));
      });
    }

    final customerInfo = await RevenueCatStore.instance.getCustomerInfo(
      appUserId: services.auth.currentUserId,
    );
    if (customerInfo == null) return;

    final isPremium = RevenueCatStore.instance.isPremium(customerInfo);
    if (isPremium != _state.isPremium) {
      await setPremium(isPremium);
    }
  }

  void _scheduleStateSync() {
    if (!_state.isAuthenticated || !services.auth.hasActiveSession) {
      return;
    }
    _syncTimer?.cancel();
    _syncTimer = Timer(_syncDebounce, () {
      _persistStateToRemote();
    });
  }

  Future<void> _persistStateToRemote() async {
    if (!_state.isAuthenticated || !services.auth.hasActiveSession) {
      return;
    }
    try {
      await services.appState.save(
        onboardingComplete: _state.onboardingComplete,
        biometricEnabled: _state.biometricEnabled,
        themePreference: _state.themePreference,
        onboardingProfile: _state.onboardingProfile,
        lastReflection: _state.lastReflection,
      );
    } catch (error, stackTrace) {
      AppLogger.error('AppController._persistStateToRemote', error, stackTrace);
    }
  }

  Future<void> _hydrateFromServices({
    required bool setAuthenticatedFromSession,
    required bool pushIfMissing,
    required bool notifyAfter,
  }) async {
    try {
      final hasSession = services.auth.hasActiveSession;
      if (!hasSession) {
        if (setAuthenticatedFromSession) {
          final preservedTheme = _state.themePreference;
          _state = AppState.initial().copyWith(themePreference: preservedTheme);
          _recomputeInsights();
        }
        if (notifyAfter) notifyListeners();
        return;
      }

      final persisted = await services.appState.load();
      final premium = await services.subscription.isPremium();

      var next = _state.copyWith(isPremium: premium);
      if (setAuthenticatedFromSession) {
        next = next.copyWith(isAuthenticated: true);
      }

      if (persisted != null) {
        next = next.copyWith(
          onboardingComplete: persisted.onboardingComplete,
          biometricEnabled: persisted.biometricEnabled,
          themePreference: persisted.themePreference,
          onboardingProfile: persisted.onboardingProfile,
          lastReflection: persisted.lastReflection,
        );
      } else if (setAuthenticatedFromSession && !next.onboardingComplete) {
        next = next.copyWith(onboardingComplete: true);
      }

      _state = next;
      _recomputeInsights();

      if (persisted == null && pushIfMissing) {
        await _persistStateToRemote();
      }
    } catch (error, stackTrace) {
      AppLogger.error('AppController._hydrateFromServices', error, stackTrace);
    }

    if (notifyAfter) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required this.controller,
    required super.child,
  }) : super(notifier: controller);

  final AppController controller;

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in widget tree.');
    return scope!.controller;
  }
}
