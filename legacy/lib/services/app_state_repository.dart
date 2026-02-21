import '../core/theme/theme_preference.dart';
import '../features/onboarding/model/onboarding_profile.dart';

class PersistedAppState {
  const PersistedAppState({
    required this.onboardingComplete,
    required this.biometricEnabled,
    required this.themePreference,
    required this.onboardingProfile,
    required this.lastReflection,
  });

  final bool onboardingComplete;
  final bool biometricEnabled;
  final ThemePreference themePreference;
  final OnboardingProfile onboardingProfile;
  final String? lastReflection;
}

abstract class AppStateRepository {
  Future<PersistedAppState?> load();

  Future<void> save({
    required bool onboardingComplete,
    required bool biometricEnabled,
    required ThemePreference themePreference,
    required OnboardingProfile onboardingProfile,
    required String? lastReflection,
  });
}

class StubAppStateRepository implements AppStateRepository {
  PersistedAppState? _value;

  @override
  Future<PersistedAppState?> load() async => _value;

  @override
  Future<void> save({
    required bool onboardingComplete,
    required bool biometricEnabled,
    required ThemePreference themePreference,
    required OnboardingProfile onboardingProfile,
    required String? lastReflection,
  }) async {
    _value = PersistedAppState(
      onboardingComplete: onboardingComplete,
      biometricEnabled: biometricEnabled,
      themePreference: themePreference,
      onboardingProfile: onboardingProfile,
      lastReflection: lastReflection,
    );
  }
}
