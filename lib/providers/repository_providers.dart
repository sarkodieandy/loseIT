import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/community_repository.dart';
import '../data/repositories/journal_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/relapse_repository.dart';
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

final relapseRepositoryProvider = Provider<RelapseRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RelapseRepository(client);
});
