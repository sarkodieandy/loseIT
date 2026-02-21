import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post.dart';

class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  Stream<List<CommunityPost>> streamFeed() {
    return _client
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows
            .take(100)
            .map((row) => CommunityPost.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ))
            .toList(growable: false));
  }

  Future<CommunityPost> createPost({
    required String content,
    required String anonymousName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final payload = <String, dynamic>{
      'user_id': user.id,
      'anonymous_name': anonymousName,
      'content': content,
    };

    final row = await _client.from('community_posts').insert(payload).select().single();
    return CommunityPost.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> likePost(String id, int currentLikes) async {
    await _client
        .from('community_posts')
        .update(<String, dynamic>{'likes': currentLikes + 1})
        .eq('id', id);
  }
}
