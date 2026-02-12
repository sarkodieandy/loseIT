import 'package:flutter/foundation.dart';

import '../core/models/risk_level.dart';
import '../features/onboarding/model/onboarding_profile.dart';

@immutable
class AppState {
  final bool onboardingComplete;
  final bool isAuthenticated;
  final bool biometricEnabled;
  final bool isPremium;

  final OnboardingProfile onboardingProfile;

  final int streakDays;
  final double streakProgress;
  final int improvementPercent;
  final RiskLevel riskLevel;
  final int urgeProbabilityPercent;

  final String? lastReflection;

  const AppState({
    required this.onboardingComplete,
    required this.isAuthenticated,
    required this.biometricEnabled,
    required this.isPremium,
    required this.onboardingProfile,
    required this.streakDays,
    required this.streakProgress,
    required this.improvementPercent,
    required this.riskLevel,
    required this.urgeProbabilityPercent,
    required this.lastReflection,
  });

  factory AppState.initial() {
    return AppState(
      onboardingComplete: false,
      isAuthenticated: false,
      biometricEnabled: false,
      isPremium: false,
      onboardingProfile: OnboardingProfile.initial(),
      streakDays: 6,
      streakProgress: 0.66,
      improvementPercent: 38,
      riskLevel: RiskLevel.medium,
      urgeProbabilityPercent: 24,
      lastReflection: null,
    );
  }

  AppState copyWith({
    bool? onboardingComplete,
    bool? isAuthenticated,
    bool? biometricEnabled,
    bool? isPremium,
    OnboardingProfile? onboardingProfile,
    int? streakDays,
    double? streakProgress,
    int? improvementPercent,
    RiskLevel? riskLevel,
    int? urgeProbabilityPercent,
    String? lastReflection,
  }) {
    return AppState(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isPremium: isPremium ?? this.isPremium,
      onboardingProfile: onboardingProfile ?? this.onboardingProfile,
      streakDays: streakDays ?? this.streakDays,
      streakProgress: streakProgress ?? this.streakProgress,
      improvementPercent: improvementPercent ?? this.improvementPercent,
      riskLevel: riskLevel ?? this.riskLevel,
      urgeProbabilityPercent:
          urgeProbabilityPercent ?? this.urgeProbabilityPercent,
      lastReflection: lastReflection ?? this.lastReflection,
    );
  }
}
