import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/group_message.dart';
import '../data/services/local_cache_service.dart';
import 'app_providers.dart';
import 'data_providers.dart';

final groupChatLastSeenProvider =
    FutureProvider.family<DateTime?, String>((ref, groupId) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return null;
  try {
    return await LocalCacheService.instance.getGroupChatLastSeen(
      userId: userId,
      groupId: groupId,
    );
  } catch (_) {
    return null;
  }
});

final groupChatHasUnreadProvider = Provider.family<bool, String>((ref, groupId) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return false;

  final messagesAsync = ref.watch(groupMessagesProvider(groupId));
  final lastSeenAsync = ref.watch(groupChatLastSeenProvider(groupId));
  if (messagesAsync.hasError || lastSeenAsync.hasError) return false;

  final messages = messagesAsync.asData?.value;
  if (messages == null || messages.isEmpty) return false;
  if (lastSeenAsync.isLoading) return false;

  final lastSeen = lastSeenAsync.asData?.value;

  GroupMessage? latestOther;
  for (final message in messages) {
    if (message.senderId != userId) {
      latestOther = message;
      break;
    }
  }
  if (latestOther == null) return false;

  if (lastSeen == null) return true;
  return latestOther.createdAt.toUtc().isAfter(lastSeen);
});

final anyGroupChatHasUnreadProvider = Provider<bool>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return false;

  final joinedAsync = ref.watch(userChallengesProvider);
  final joined = joinedAsync.asData?.value;
  if (joined == null || joined.isEmpty) return false;

  for (final item in joined) {
    if (ref.watch(groupChatHasUnreadProvider(item.challengeId))) return true;
  }

  return false;
});
