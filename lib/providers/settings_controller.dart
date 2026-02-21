import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/local_cache_service.dart';

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.onboardingComplete,
  });

  final ThemeMode themeMode;
  final bool onboardingComplete;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? onboardingComplete,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  static const SettingsState initial = SettingsState(
    themeMode: ThemeMode.system,
    onboardingComplete: false,
  );
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(SettingsState.initial) {
    _load();
  }

  Future<void> _load() async {
    final cache = LocalCacheService.instance;
    final storedTheme = await cache.getThemeMode();
    final onboarded = await cache.getOnboardingComplete();
    state = state.copyWith(
      themeMode: storedTheme ?? state.themeMode,
      onboardingComplete: onboarded ?? state.onboardingComplete,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await LocalCacheService.instance.setThemeMode(mode);
  }

  Future<void> setOnboardingComplete(bool value) async {
    state = state.copyWith(onboardingComplete: value);
    await LocalCacheService.instance.setOnboardingComplete(value);
  }
}
