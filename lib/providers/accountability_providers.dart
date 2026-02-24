import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/accountability_partner.dart';
import '../data/models/accountability_weekly_report.dart';
import '../data/models/emergency_sos_contact.dart';
import '../data/models/craving_log.dart';
import '../data/models/coping_strategy.dart';
import '../data/models/recovery_workbook_module.dart';
import '../data/models/user_workbook_progress.dart';
import './app_providers.dart';

// ========== ACCOUNTABILITY PARTNERS ==========

final accountabilityPartnersProvider =
    FutureProvider.family<List<AccountabilityPartner>, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getAccountabilityPartners(userId);
});

final createAccountabilityPartnerProvider =
    FutureProvider.family<bool, (String, String)>((ref, params) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createAccountabilityPartner(params.$1, params.$2);
  if (result) {
    ref.invalidate(accountabilityPartnersProvider(params.$1));
  }
  return result;
});

// ========== WEEKLY REPORTS ==========

final weeklyReportProvider =
    FutureProvider.family<AccountabilityWeeklyReport?, (String, DateTime)>(
        (ref, params) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getWeeklyReport(params.$1, params.$2);
});

// ========== EMERGENCY SOS CONTACTS ==========

final emergencySosContactsProvider =
    FutureProvider.family<List<EmergencySosContact>, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getEmergencySosContacts(userId);
});

final addEmergencySosProvider =
    FutureProvider.family<bool, EmergencySosContact>((ref, contact) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.addEmergencySosContact(contact);
  if (result) {
    ref.invalidate(emergencySosContactsProvider(contact.userId));
  }
  return result;
});

// ========== CRAVING LOGS ==========

final cravingLogsProvider =
    FutureProvider.family<List<CravingLog>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getCravingLogs(userId);
});

final logCravingProvider =
    FutureProvider.family<bool, CravingLog>((ref, craving) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.logCraving(craving);
  if (result) {
    ref.invalidate(cravingLogsProvider(craving.userId));
  }
  return result;
});

// ========== COPING STRATEGIES ==========

final copingStrategiesProvider =
    FutureProvider<List<CopingStrategy>>((ref) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final isPremium = ref.watch(premiumControllerProvider);
  return repo.getCopingStrategies(premiumOnly: !isPremium.isPremium);
});

// ========== RECOVERY WORKBOOK ==========

final recoveryModulesProvider =
    FutureProvider<List<RecoveryWorkbookModule>>((ref) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final isPremium = ref.watch(premiumControllerProvider);
  return repo.getRecoveryModules(premiumOnly: !isPremium.isPremium);
});

final moduleProgressProvider =
    FutureProvider.family<UserWorkbookProgress?, (String, String)>(
        (ref, params) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getModuleProgress(params.$1, params.$2);
});

final completeModuleProvider =
    FutureProvider.family<bool, (String, String)>((ref, params) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.completeModule(params.$1, params.$2);
  if (result) {
    ref.invalidate(moduleProgressProvider(params));
  }
  return result;
});

// ========== AUTO-REFRESH on init ==========
// Invalidate providers when the app starts to fetch fresh data
final premiumFeaturesRefreshProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return;

  // Refresh all premium features
  ref.invalidate(accountabilityPartnersProvider(userId));
  ref.invalidate(emergencySosContactsProvider(userId));
  ref.invalidate(cravingLogsProvider(userId));
  ref.invalidate(copingStrategiesProvider);
  ref.invalidate(recoveryModulesProvider);

  return;
});
