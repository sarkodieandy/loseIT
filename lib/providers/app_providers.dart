import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/revenuecat_service.dart';
import '../data/services/emergency_sos_service.dart';
import '../data/services/ai_relapse_predictor_service.dart';
import '../data/services/badge_service.dart';
import '../data/repositories/premium_features_repository.dart';
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
    StateNotifierProvider<PremiumController, PremiumStatus>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PremiumController(RevenueCatService.instance, client);
});

/// Helper: true if user has premium access (paid or active trial)
final isPremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumControllerProvider);
  return status.hasAccess;
});

/// Helper: true if only trial is active (not paid)
final isTrialOnlyProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumControllerProvider);
  return status.isTrialActive && !status.isPremium;
});

/// Helper: trial days remaining
final trialDaysProvider = Provider<int>((ref) {
  final status = ref.watch(premiumControllerProvider);
  return status.trialDaysRemaining;
});

final emergencySosSessionProvider = StreamProvider<dynamic>((ref) {
  return EmergencySosService.instance.sessionStream;
});
final aiRelapsePredictorProvider = Provider<AiRelapsePredictorService>((ref) {
  return AiRelapsePredictorService.instance;
});

final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService.instance;
});
final premiumFeaturesRepositoryProvider =
    Provider<PremiumFeaturesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PremiumFeaturesRepository(client);
});

// ========== USER CONTEXT ==========

final userIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.user.id;
});
