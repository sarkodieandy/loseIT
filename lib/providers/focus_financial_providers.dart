import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/focus_session.dart';
import '../data/models/morning_evening_routine.dart';
import '../data/models/sobriety_affirmation.dart';
import '../data/models/financial_goal.dart';
import '../data/models/spending_log.dart';
import '../data/models/charity_donation.dart';
import './app_providers.dart';

// ========== FOCUS SESSIONS ==========

final focusSessionsProvider =
    FutureProvider.family<List<FocusSession>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getFocusSessions(userId);
});

final createFocusSessionProvider =
    FutureProvider.family<bool, FocusSession>((ref, session) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createFocusSession(session);
  if (result) {
    ref.invalidate(focusSessionsProvider(session.userId));
  }
  return result;
});

// ========== MORNING/EVENING ROUTINES ==========

final routinesProvider =
    FutureProvider.family<List<MorningEveningRoutine>, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getRoutines(userId);
});

final createRoutineProvider =
    FutureProvider.family<bool, MorningEveningRoutine>((ref, routine) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createRoutine(routine);
  if (result) {
    ref.invalidate(routinesProvider(routine.userId));
  }
  return result;
});

// ========== SOBRIETY AFFIRMATIONS ==========

final sobrietyAffirmationsProvider =
    FutureProvider.family<List<SobrietyAffirmation>, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getSobrietyAffirmations(userId);
});

final createAffirmationProvider =
    FutureProvider.family<bool, SobrietyAffirmation>((ref, affirmation) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createAffirmation(affirmation);
  if (result) {
    ref.invalidate(sobrietyAffirmationsProvider(affirmation.userId));
  }
  return result;
});

// ========== FINANCIAL GOALS ==========

final financialGoalsProvider =
    FutureProvider.family<List<FinancialGoal>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getFinancialGoals(userId);
});

final createFinancialGoalProvider =
    FutureProvider.family<bool, FinancialGoal>((ref, goal) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createFinancialGoal(goal);
  if (result) {
    ref.invalidate(financialGoalsProvider(goal.userId));
  }
  return result;
});

// ========== SPENDING LOGS ==========

final spendingLogsProvider =
    FutureProvider.family<List<SpendingLog>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getSpendingLogs(userId);
});

final logSpendingProvider =
    FutureProvider.family<bool, SpendingLog>((ref, log) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.logSpending(log);
  if (result) {
    ref.invalidate(spendingLogsProvider(log.userId));
  }
  return result;
});

// ========== CHARITY DONATIONS ==========

final charityDonationsProvider =
    FutureProvider.family<List<CharityDonation>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getCharityDonations(userId);
});

final recordCharityDonationProvider =
    FutureProvider.family<bool, CharityDonation>((ref, donation) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.recordCharityDonation(donation);
  if (result) {
    ref.invalidate(charityDonationsProvider(donation.userId));
  }
  return result;
});

// ========== FINANCIAL INSIGHTS (computed) ==========

final financialInsightsProvider = FutureProvider.family<
    ({double totalSaved, double totalSpent, int completedGoals}),
    String>((ref, userId) async {
  final goals = await ref.watch(financialGoalsProvider(userId).future);
  final spending = await ref.watch(spendingLogsProvider(userId).future);

  final totalSpent = spending.fold<double>(0, (sum, log) => sum + log.amount);
  final completedGoals = goals.where((g) => g.isCompleted).length;
  final totalSaved = goals.fold<double>(
      0, (sum, g) => sum + (g.isCompleted ? g.currentAmount : 0));

  return (
    totalSaved: totalSaved,
    totalSpent: totalSpent,
    completedGoals: completedGoals
  );
});
