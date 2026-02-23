import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/badges_repository.dart';
import '../data/repositories/challenges_repository.dart';
import '../data/repositories/community_repository.dart';
import '../data/repositories/dm_repository.dart';
import '../data/repositories/emergency_sessions_repository.dart';
import '../data/repositories/habits_repository.dart';
import '../data/repositories/journal_repository.dart';
import '../data/repositories/milestones_repository.dart';
import '../data/repositories/mood_repository.dart';
import '../data/repositories/prompts_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/relapse_repository.dart';
import '../data/repositories/support_repository.dart';
import '../data/repositories/urge_repository.dart';
import 'app_providers.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ProfileRepository(client);
});

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return JournalRepository(client);
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CommunityRepository(client);
});

final dmRepositoryProvider = Provider<DmRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DmRepository(client);
});

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HabitsRepository(client);
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MoodRepository(client);
});

final challengesRepositoryProvider = Provider<ChallengesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChallengesRepository(client);
});

final badgesRepositoryProvider = Provider<BadgesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BadgesRepository(client);
});

final promptsRepositoryProvider = Provider<PromptsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PromptsRepository(client);
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupportRepository(client);
});

final milestonesRepositoryProvider = Provider<MilestonesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return MilestonesRepository(client);
});

final relapseRepositoryProvider = Provider<RelapseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RelapseRepository(client);
});

final urgeRepositoryProvider = Provider<UrgeRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return UrgeRepository(client);
});
final emergencySessionsRepositoryProvider =
    Provider<EmergencySessionsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmergencySessionsRepository(client);
});
