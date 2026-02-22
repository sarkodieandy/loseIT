import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/community_post.dart';
import '../data/models/community_reply.dart';
import '../data/models/dm_message.dart';
import '../data/models/dm_thread.dart';
import '../data/models/user_habit.dart';
import '../data/models/mood_log.dart';
import '../data/models/challenge.dart';
import '../data/models/group_checkin.dart';
import '../data/models/user_challenge.dart';
import '../data/models/badge.dart';
import '../data/models/user_badge.dart';
import '../data/models/daily_prompt.dart';
import '../data/models/support_connection.dart';
import '../data/models/support_message.dart';
import '../data/models/custom_milestone.dart';
import '../data/models/journal_entry.dart';
import '../data/models/relapse_log.dart';
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

final communityFeedProvider =
    StreamProvider.family<List<CommunityPost>, String?>((ref, category) {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.streamFeed(category: category);
});

final communityOnlineCountProvider = StreamProvider<int>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) {
    return Stream<int>.value(0);
  }

  final channel = client.channel('community:online');
  final controller = StreamController<int>();

  void emit() {
    final states = channel.presenceState();
    final count = states.fold<int>(
      0,
      (total, entry) => total + entry.presences.length,
    );
    if (!controller.isClosed) {
      controller.add(count);
    }
  }

  channel
      .onPresenceSync((_) => emit())
      .onPresenceJoin((_) => emit())
      .onPresenceLeave((_) => emit())
      .subscribe((status, [error]) async {
    if (status == RealtimeSubscribeStatus.subscribed) {
      await channel.track(
        <String, dynamic>{
          'user_id': session.user.id,
          'online_at': DateTime.now().toIso8601String(),
        },
      );
      emit();
    }
  });

  Future<void> cleanup() async {
    try {
      await channel.untrack();
    } catch (_) {}
    try {
      await client.removeChannel(channel);
    } catch (_) {}
    await controller.close();
  }

  ref.onDispose(() => unawaited(cleanup()));

  return controller.stream;
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

final habitsProvider = FutureProvider<List<UserHabit>>((ref) {
  final repository = ref.watch(habitsRepositoryProvider);
  return repository.fetchHabits();
});

final moodLogsProvider = FutureProvider<List<MoodLog>>((ref) {
  final repository = ref.watch(moodRepositoryProvider);
  return repository.fetchLogs();
});

final challengesProvider = FutureProvider<List<Challenge>>((ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  return repository.fetchChallenges();
});

final userChallengesProvider = FutureProvider<List<UserChallenge>>((ref) {
  final repository = ref.watch(challengesRepositoryProvider);
  return repository.fetchUserChallenges();
});

final groupProvider = FutureProvider.family<Challenge?, String>((ref, groupId) {
  final repository = ref.watch(challengesRepositoryProvider);
  return repository.fetchGroup(groupId);
});

final groupCheckinsProvider =
    StreamProvider.family<List<GroupCheckin>, String>((ref, groupId) {
  final repository = ref.watch(challengesRepositoryProvider);
  return repository.streamGroupCheckins(groupId);
});

final badgesProvider = FutureProvider<List<Badge>>((ref) {
  final repository = ref.watch(badgesRepositoryProvider);
  return repository.fetchBadges();
});

final userBadgesProvider = FutureProvider<List<UserBadge>>((ref) {
  final repository = ref.watch(badgesRepositoryProvider);
  return repository.fetchUserBadges();
});

final promptsProvider = FutureProvider.family<List<DailyPrompt>, bool>((ref, isPremium) {
  final repository = ref.watch(promptsRepositoryProvider);
  return repository.fetchPrompts(includePremium: isPremium);
});

final supportConnectionsProvider = FutureProvider<List<SupportConnection>>((ref) {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.fetchConnections();
});

final supportMessagesProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, connectionId) {
  final repository = ref.watch(supportRepositoryProvider);
  return repository.streamMessages(connectionId);
});

final customMilestonesProvider = FutureProvider<List<CustomMilestone>>((ref) {
  final repository = ref.watch(milestonesRepositoryProvider);
  return repository.fetchMilestones();
});

final relapseLogsProvider = FutureProvider<List<RelapseLog>>((ref) {
  final repository = ref.watch(relapseRepositoryProvider);
  return repository.fetchLogs();
});
