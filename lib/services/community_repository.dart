import '../features/community/model/community_models.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchFeed();
  Future<CommunityGroup> joinGroup({required String code});
  Future<CommunityGroup> createGroup({required String name});
  Future<List<ChatMessage>> fetchChat({required String groupId});
  Future<void> sendMessage({required String groupId, required String message});
}

class StubCommunityRepository implements CommunityRepository {
  @override
  Future<CommunityGroup> createGroup({required String name}) {
    throw UnimplementedError('Connect Supabase later.');
  }

  @override
  Future<List<CommunityPost>> fetchFeed() async => const <CommunityPost>[];

  @override
  Future<List<ChatMessage>> fetchChat({required String groupId}) async =>
      const <ChatMessage>[];

  @override
  Future<CommunityGroup> joinGroup({required String code}) {
    throw UnimplementedError('Connect Supabase later.');
  }

  @override
  Future<void> sendMessage(
      {required String groupId, required String message}) async {
    return;
  }
}
