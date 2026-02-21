import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/community_post.dart';
import '../data/models/community_reply.dart';
import '../data/models/dm_message.dart';
import '../data/models/dm_thread.dart';
import '../data/models/journal_entry.dart';
import '../data/models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/journal_controller.dart';
import '../providers/profile_controller.dart';
import 'repository_providers.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
  ref.watch(sessionProvider);
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileController(repository);
});

final journalControllerProvider =
    StateNotifierProvider<JournalController, AsyncValue<List<JournalEntry>>>((
  ref,
) {
  final repository = ref.watch(journalRepositoryProvider);
  return JournalController(repository);
});

final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.streamFeed();
});

final communityPostProvider = FutureProvider.family<CommunityPost?, String>((ref, postId) {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.fetchPost(postId);
});

final communityRepliesProvider =
    StreamProvider.family<List<CommunityReply>, String>((ref, postId) {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.streamReplies(postId);
});

final dmThreadsProvider = StreamProvider<List<DmThread>>((ref) {
  final repository = ref.watch(dmRepositoryProvider);
  return repository.streamThreads();
});

final dmMessagesProvider = StreamProvider.family<List<DmMessage>, String>((ref, threadId) {
  final repository = ref.watch(dmRepositoryProvider);
  return repository.streamMessages(threadId);
});
