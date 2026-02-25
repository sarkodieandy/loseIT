import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/community_post.dart';
import '../models/community_reply.dart';

class CommunityRepository {
  CommunityRepository(this._client);

  final SupabaseClient _client;

  Stream<List<CommunityPost>> streamFeed({String? category}) {
    final normalized = category?.trim().toLowerCase();
    final base = _client
        .from('community_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100);

    // Prefer server-side filtering when the schema supports it, but keep the
    // app resilient if `category` isn't present yet in the user's DB.
    return base
        .map((rows) => rows
            .map((row) => CommunityPost.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ))
            .toList(growable: false))
        .map((posts) {
      if (normalized == null || normalized.isEmpty || normalized == 'all') {
        return posts;
      }

      final hasAnyCategory =
          posts.any((p) => (p.category ?? '').trim().isNotEmpty);
      if (!hasAnyCategory) {
        return posts;
      }

      return posts
          .where(
            (p) => (p.category ?? '').trim().toLowerCase() == normalized,
          )
          .toList(growable: false);
    });
  }

  Future<CommunityPost?> fetchPost(String id) async {
    try {
      final parsedId = int.tryParse(id);
      final row = await _client
          .from('community_posts')
          .select()
          .eq('id', parsedId ?? id)
          .maybeSingle();
      if (row == null) return null;
      return CommunityPost.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('community.fetchPost', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('community.fetchPost', error, stackTrace);
      rethrow;
    }
  }

  Future<CommunityPost> createPost({
    required String content,
    required String anonymousName,
    String? category,
    String? topic,
    String? badge,
    int? streakDays,
    String? streakLabel,
  }) async {
    final user = _client.auth.currentUser;
    AppLogger.info('Community createPost userId=${user?.id}');
    if (user == null) throw const AuthException('Not authenticated');

    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Post content is empty.');
    }

    final payload = <String, dynamic>{
      'user_id': user.id,
      'anonymous_name': anonymousName,
      'alias': anonymousName,
      'content': trimmed,
      'message': trimmed,
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim().toLowerCase(),
      if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
      if (badge != null && badge.trim().isNotEmpty) 'badge': badge.trim(),
      if (streakDays != null) 'streak_days': streakDays,
      if (streakLabel != null && streakLabel.trim().isNotEmpty)
        'streak_label': streakLabel.trim(),
    };
    AppLogger.info(
      'Community createPost payload contentLength=${trimmed.length} alias=$anonymousName',
    );

    try {
      final row = await _client.from('community_posts').insert(payload).select().single();
      AppLogger.info('Community createPost success id=${row['id']}');
      return CommunityPost.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      final message = error.message;
      if (message.contains('column \"category\"') ||
          message.contains('column \"topic\"') ||
          message.contains('column \"badge\"') ||
          message.contains('column \"streak_days\"') ||
          message.contains('column \"streak_label\"')) {
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..remove('category')
          ..remove('topic')
          ..remove('badge')
          ..remove('streak_days')
          ..remove('streak_label');
        final row = await _client
            .from('community_posts')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createPost success id=${row['id']} (no extra columns)');
        return CommunityPost.fromJson(Map<String, dynamic>.from(row));
      }
      if (message.contains('column \"anonymous_name\"') ||
          message.contains('column \"content\"')) {
        final fallbackPayload = <String, dynamic>{
          'user_id': user.id,
          'alias': anonymousName,
          'message': trimmed,
        };
        final row = await _client
            .from('community_posts')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createPost success id=${row['id']} (legacy columns)');
        return CommunityPost.fromJson(Map<String, dynamic>.from(row));
      }
      if (message.contains('null value in column \"message\"') ||
          message.contains('null value in column \"alias\"')) {
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..['alias'] = anonymousName
          ..['message'] = trimmed;
        final row = await _client
            .from('community_posts')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createPost success id=${row['id']} (retry)');
        return CommunityPost.fromJson(Map<String, dynamic>.from(row));
      }
      if (error.message.contains('column \"alias\"') ||
          error.message.contains('column \"alias\" of relation')) {
        final fallbackPayload = Map<String, dynamic>.from(payload)..remove('alias');
        final row = await _client
            .from('community_posts')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createPost success id=${row['id']} (fallback)');
        return CommunityPost.fromJson(Map<String, dynamic>.from(row));
      }
      AppLogger.error('community.createPost', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('community.createPost', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<CommunityReply>> streamReplies(String postId) {
    final parsedPostId = int.tryParse(postId);
    return _client
        .from('community_replies')
        .stream(primaryKey: ['id'])
        .eq('post_id', parsedPostId ?? postId)
        .order('created_at')
        .limit(200)
        .map((rows) => rows
            .map((row) => CommunityReply.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ))
            .toList(growable: false));
  }

  Future<CommunityReply> createReply({
    required String postId,
    required String content,
    required String anonymousName,
  }) async {
    final user = _client.auth.currentUser;
    AppLogger.info('Community createReply userId=${user?.id} postId=$postId');
    if (user == null) throw const AuthException('Not authenticated');

    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Reply content is empty.');
    }

    final parsedPostId = int.tryParse(postId);
    final payload = <String, dynamic>{
      'post_id': parsedPostId ?? postId,
      'user_id': user.id,
      'anonymous_name': anonymousName,
      'alias': anonymousName,
      'content': trimmed,
      'message': trimmed,
    };
    AppLogger.info(
      'Community createReply payload contentLength=${trimmed.length} alias=$anonymousName',
    );

    try {
      final row =
          await _client.from('community_replies').insert(payload).select().single();
      AppLogger.info('Community createReply success id=${row['id']}');
      return CommunityReply.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      final message = error.message;
      if (message.contains('column \"anonymous_name\"') ||
          message.contains('column \"content\"')) {
        final fallbackPayload = <String, dynamic>{
          'post_id': parsedPostId ?? postId,
          'user_id': user.id,
          'alias': anonymousName,
          'message': trimmed,
        };
        final row = await _client
            .from('community_replies')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createReply success id=${row['id']} (legacy columns)');
        return CommunityReply.fromJson(Map<String, dynamic>.from(row));
      }
      if (message.contains('null value in column \"message\"') ||
          message.contains('null value in column \"alias\"')) {
        final fallbackPayload = Map<String, dynamic>.from(payload)
          ..['alias'] = anonymousName
          ..['message'] = trimmed;
        final row = await _client
            .from('community_replies')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createReply success id=${row['id']} (retry)');
        return CommunityReply.fromJson(Map<String, dynamic>.from(row));
      }
      if (error.message.contains('column \"alias\"') ||
          error.message.contains('column \"alias\" of relation')) {
        final fallbackPayload = Map<String, dynamic>.from(payload)..remove('alias');
        final row = await _client
            .from('community_replies')
            .insert(fallbackPayload)
            .select()
            .single();
        AppLogger.info('Community createReply success id=${row['id']} (fallback)');
        return CommunityReply.fromJson(Map<String, dynamic>.from(row));
      }
      AppLogger.error('community.createReply', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('community.createReply', error, stackTrace);
      rethrow;
    }
  }

  Future<void> likePost(String id, int currentLikes) async {
    try {
      // Preferred: atomic increment via RPC (works with strict RLS).
      await _client.rpc(
        'community_like_post',
        params: <String, dynamic>{'post_id': id},
      );
      return;
    } on PostgrestException catch (error, stackTrace) {
      // Backward compatibility: RPC may not exist yet.
      // 42883 = undefined_function
      if (error.code == '42883') {
        AppLogger.warn(
          'community.likePost: RPC missing (community_like_post). Falling back to direct update.',
        );
      } else {
        AppLogger.error('community.likePost', error, stackTrace);
        rethrow;
      }
    } catch (error, stackTrace) {
      AppLogger.error('community.likePost', error, stackTrace);
      rethrow;
    }

    // Fallback (legacy): direct update. Note this will fail under strict RLS for
    // non-owners, but keeps older deployments working when RLS isn't enabled.
    try {
      final parsedId = int.tryParse(id);
      await _client
          .from('community_posts')
          .update(<String, dynamic>{'likes': currentLikes + 1})
          .eq('id', parsedId ?? id);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('community.likePost', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('community.likePost', error, stackTrace);
      rethrow;
    }
  }

  Future<void> reactPost(String id, String field, int currentValue) async {
    try {
      final parsedId = int.tryParse(id);
      await _client
          .from('community_posts')
          .update(<String, dynamic>{field: currentValue + 1})
          .eq('id', parsedId ?? id);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('community.reactPost', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('community.reactPost', error, stackTrace);
      rethrow;
    }
  }
}
