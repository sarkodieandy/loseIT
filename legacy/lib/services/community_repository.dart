import '../features/community/model/community_models.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchFeed();
  Future<CommunityPost> createPost({
    required CommunityPostKind kind,
    required String message,
    required int streakDays,
    String? topic,
    String? label,
  });
  Future<List<CommunityPostReply>> fetchReplies({required int postId});
  Future<CommunityPostReply> createReply({
    required int postId,
    required String message,
    required int streakDays,
  });
  Future<List<CommunityGroup>> fetchMyGroups();
  Future<CommunityGroup> joinGroup({required String code});
  Future<CommunityGroup> createGroup({required String name});
  Future<List<ChatMessage>> fetchChat({
    String? groupId,
    String? peerAlias,
  });
  Future<void> sendMessage({
    String? groupId,
    String? peerAlias,
    required String message,
    String? replyToAlias,
    String? replyToText,
  });
}

class StubCommunityRepository implements CommunityRepository {
  int _fakeId = 1;

  @override
  Future<CommunityGroup> createGroup({required String name}) {
    throw UnimplementedError('Connect Supabase later.');
  }

  @override
  Future<CommunityPost> createPost({
    required CommunityPostKind kind,
    required String message,
    required int streakDays,
    String? topic,
    String? label,
  }) async {
    return CommunityPost(
      id: _fakeId++,
      kind: kind,
      alias: 'Guest',
      streakDays: streakDays,
      topic: topic,
      label: label,
      message: message,
      minutesAgo: 0,
      supportCount: 0,
      commentCount: 0,
    );
  }

  @override
  Future<List<CommunityPost>> fetchFeed() async => const <CommunityPost>[];

  @override
  Future<CommunityPostReply> createReply({
    required int postId,
    required String message,
    required int streakDays,
  }) async {
    return CommunityPostReply(
      id: _fakeId++,
      postId: postId,
      alias: 'Guest',
      streakDays: streakDays,
      message: message.trim(),
      minutesAgo: 0,
      supportCount: 0,
    );
  }

  @override
  Future<List<ChatMessage>> fetchChat({
    String? groupId,
    String? peerAlias,
  }) async =>
      const <ChatMessage>[];

  @override
  Future<List<CommunityPostReply>> fetchReplies({required int postId}) async =>
      const <CommunityPostReply>[];

  @override
  Future<List<CommunityGroup>> fetchMyGroups() async =>
      const <CommunityGroup>[];

  @override
  Future<CommunityGroup> joinGroup({required String code}) {
    throw UnimplementedError('Connect Supabase later.');
  }

  @override
  Future<void> sendMessage({
    String? groupId,
    String? peerAlias,
    required String message,
    String? replyToAlias,
    String? replyToText,
  }) async {
    return;
  }
}
