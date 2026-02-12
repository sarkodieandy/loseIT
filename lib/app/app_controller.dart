import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/models/risk_level.dart';
import '../features/onboarding/model/onboarding_profile.dart';
import '../services/discipline_services.dart';
import 'app_state.dart';

class AppController extends ChangeNotifier {
  AppController({DisciplineServices? services})
      : services = services ?? DisciplineServices.stub();

  final DisciplineServices services;

  AppState _state = AppState.initial();
  AppState get state => _state;

  void updateOnboardingProfile(OnboardingProfile profile) {
    _state = _state.copyWith(onboardingProfile: profile);
    _recomputeInsights();
    notifyListeners();
  }

  void completeOnboarding({required bool isPremium}) {
    _state = _state.copyWith(onboardingComplete: true, isPremium: isPremium);
    _recomputeInsights();
    notifyListeners();
  }

  void completeAuth({required bool biometricEnabled}) {
    _state = _state.copyWith(
      isAuthenticated: true,
      biometricEnabled: biometricEnabled,
    );
    notifyListeners();
  }

  void signOut() {
    _state = _state.copyWith(isAuthenticated: false);
    notifyListeners();
  }

  void setPremium(bool value) {
    _state = _state.copyWith(isPremium: value);
    notifyListeners();
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
    _state = _state.copyWith(lastReflection: text.trim().isEmpty ? null : text);
    notifyListeners();
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
