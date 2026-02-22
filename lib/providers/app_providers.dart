import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/revenuecat_service.dart';
import 'settings_controller.dart';
import 'premium_controller.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsControllerProvider).themeMode;
});

final onboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(settingsControllerProvider).onboardingComplete;
});

final premiumControllerProvider =
    StateNotifierProvider<PremiumController, bool>((ref) {
  return PremiumController(RevenueCatService.instance);
});
