import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/community/model/community_models.dart';
import '../community_repository.dart';
import 'profile_store.dart';

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final SupabaseProfileStore _profiles;
  final Random _random = Random();

  @override
  Future<List<CommunityPost>> fetchFeed() async {
    try {
      final rows = await _client
          .from('community_posts')
          .select(
            'id, alias, streak_days, message, created_at, kind, topic, label, support_count, comment_count',
          )
          .order('created_at', ascending: false)
          .limit(50) as List<dynamic>;

      return rows
          .map((raw) => _postFromRow(raw as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      if (!_looksLikeMissingColumn(error)) rethrow;

      final rows = await _client
          .from('community_posts')
          .select('id, alias, streak_days, message, created_at')
          .order('created_at', ascending: false)
          .limit(50) as List<dynamic>;

      return rows
          .map((raw) => _postFromRow(raw as Map<String, dynamic>))
          .toList(growable: false);
    }
  }

  @override
  Future<CommunityPost> createPost({
    required CommunityPostKind kind,
    required String message,
    required int streakDays,
    String? topic,
    String? label,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      throw const PostgrestException(message: 'Post message cannot be empty.');
    }

    final alias = await _profiles.aliasForCurrentUser();

    try {
      final inserted = await _client
          .from('community_posts')
          .insert(<String, dynamic>{
            'alias': alias,
            'streak_days': streakDays,
            'message': text,
            'kind': kind.id,
            if (topic != null && topic.trim().isNotEmpty) 'topic': topic.trim(),
            if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
          })
          .select(
            'id, alias, streak_days, message, created_at, kind, topic, label, support_count, comment_count',
          )
          .single();

      return _postFromRow(Map<String, dynamic>.from(inserted));
    } on PostgrestException catch (error) {
      if (!_looksLikeMissingColumn(error)) rethrow;

      final inserted = await _client
          .from('community_posts')
          .insert(<String, dynamic>{
            'alias': alias,
            'streak_days': streakDays,
            'message': text,
          })
          .select('id, alias, streak_days, message, created_at')
          .single();

      final row = Map<String, dynamic>.from(inserted);
      final base = _postFromRow(row);
      return CommunityPost(
        id: base.id,
        kind: kind,
        alias: base.alias,
        streakDays: base.streakDays,
        topic: topic,
        label: label,
        message: base.message,
        minutesAgo: base.minutesAgo,
        supportCount: base.supportCount,
        commentCount: base.commentCount,
      );
    }
  }

  @override
  Future<List<CommunityPostReply>> fetchReplies({required int postId}) async {
    try {
      final rows = await _client
          .from('community_post_replies')
          .select(
            'id, post_id, alias, streak_days, message, created_at, support_count',
          )
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(200) as List<dynamic>;

      return rows
          .map((raw) => _replyFromRow(raw as Map<String, dynamic>))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      if (_looksLikeMissingRelation(error, 'community_post_replies')) {
        throw const PostgrestException(
          message: 'Missing Supabase table: community_post_replies.',
        );
      }
      if (!_looksLikeMissingColumn(error)) rethrow;

      final rows = await _client
          .from('community_post_replies')
          .select('id, post_id, alias, streak_days, message, created_at')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(200) as List<dynamic>;

      return rows
          .map((raw) => _replyFromRow(raw as Map<String, dynamic>))
          .toList(growable: false);
    }
  }

  @override
  Future<CommunityPostReply> createReply({
    required int postId,
    required String message,
    required int streakDays,
  }) async {
    final text = message.trim();
    if (text.isEmpty) {
      throw const PostgrestException(message: 'Reply cannot be empty.');
    }

    final alias = await _profiles.aliasForCurrentUser();

    try {
      final inserted = await _client
          .from('community_post_replies')
          .insert(<String, dynamic>{
            'post_id': postId,
            'alias': alias,
            'streak_days': streakDays,
            'message': text,
          })
          .select(
            'id, post_id, alias, streak_days, message, created_at, support_count',
          )
          .single();

      return _replyFromRow(Map<String, dynamic>.from(inserted));
    } on PostgrestException catch (error) {
      if (_looksLikeMissingRelation(error, 'community_post_replies')) {
        throw const PostgrestException(
          message: 'Missing Supabase table: community_post_replies.',
        );
      }
      if (!_looksLikeMissingColumn(error)) rethrow;

      final inserted = await _client
          .from('community_post_replies')
          .insert(<String, dynamic>{
            'post_id': postId,
            'alias': alias,
            'streak_days': streakDays,
            'message': text,
          })
          .select('id, post_id, alias, streak_days, message, created_at')
          .single();

      return _replyFromRow(Map<String, dynamic>.from(inserted));
    }
  }

  @override
  Future<List<CommunityGroup>> fetchMyGroups() async {
    final alias = await _profiles.aliasForCurrentUser();
    final rows = await _client
        .from('community_group_members')
        .select('group_id')
        .eq('alias', alias) as List<dynamic>;

    final groupIds = rows
        .map((raw) => (raw as Map<String, dynamic>)['group_id'] as String?)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);

    if (groupIds.isEmpty) return const <CommunityGroup>[];

    final groups = await _client
        .from('community_groups')
        .select('id, name, code, weekly_change_percent')
        .inFilter('id', groupIds)
        .order('created_at', ascending: false) as List<dynamic>;

    final result = <CommunityGroup>[];
    for (final raw in groups) {
      final row = raw as Map<String, dynamic>;
      final id = row['id'] as String?;
      if (id == null || id.trim().isEmpty) continue;
      final members = await _fetchGroupMembers(id);
      result.add(
        CommunityGroup(
          id: id,
          name: row['name'] as String? ?? 'Group',
          code: row['code'] as String? ?? '',
          weeklyChangePercent:
              _toInt(row['weekly_change_percent'], fallback: 0),
          members: members,
        ),
      );
    }
    return result;
  }

  @override
  Future<CommunityGroup> joinGroup({required String code}) async {
    final input = code.trim();
    if (input.isEmpty) {
      throw const PostgrestException(message: 'Group code is required.');
    }

    final group = await _findGroup(input);
    if (group == null) {
      throw const PostgrestException(message: 'Group not found.');
    }

    final alias = await _profiles.aliasForCurrentUser();
    await _client.from('community_group_members').upsert(
      <String, dynamic>{
        'group_id': group['id'],
        'alias': alias,
        'streak_days': 0,
      },
      onConflict: 'group_id,alias',
    );

    final members = await _fetchGroupMembers(group['id'] as String);
    return CommunityGroup(
      id: group['id'] as String,
      name: group['name'] as String? ?? 'Group',
      code: group['code'] as String? ?? '',
      weeklyChangePercent: _toInt(group['weekly_change_percent'], fallback: 0),
      members: members,
    );
  }

  @override
  Future<CommunityGroup> createGroup({required String name}) async {
    final groupName = name.trim();
    if (groupName.isEmpty) {
      throw const PostgrestException(message: 'Group name is required.');
    }

    final groupCode = _generateCode();
    final inserted = await _client
        .from('community_groups')
        .insert(<String, dynamic>{
          'name': groupName,
          'code': groupCode,
          'weekly_change_percent': 0,
        })
        .select('id, name, code, weekly_change_percent')
        .single();

    final alias = await _profiles.aliasForCurrentUser();
    await _client.from('community_group_members').upsert(
      <String, dynamic>{
        'group_id': inserted['id'],
        'alias': alias,
        'streak_days': 0,
      },
      onConflict: 'group_id,alias',
    );

    final members = await _fetchGroupMembers(inserted['id'] as String);
    return CommunityGroup(
      id: inserted['id'] as String,
      name: inserted['name'] as String? ?? groupName,
      code: inserted['code'] as String? ?? groupCode,
      weeklyChangePercent:
          _toInt(inserted['weekly_change_percent'], fallback: 0),
      members: members,
    );
  }

  @override
  Future<List<ChatMessage>> fetchChat({
    String? groupId,
    String? peerAlias,
  }) async {
    if ((groupId == null || groupId.isEmpty) &&
        (peerAlias == null || peerAlias.isEmpty)) {
      throw const PostgrestException(
        message: 'Either groupId or peerAlias is required.',
      );
    }

    final myAlias = await _profiles.aliasForCurrentUser();
    late final List<dynamic> rows;

    if (groupId != null && groupId.isNotEmpty) {
      rows = await _client
          .from('chat_messages')
          .select('sender_alias, text, reply_to_alias, reply_to_text')
          .eq('group_id', groupId)
          .order('created_at', ascending: true) as List<dynamic>;
    } else {
      final peer = peerAlias!.trim();
      final meEscaped = _escapeFilterValue(myAlias);
      final peerEscaped = _escapeFilterValue(peer);
      rows = await _client
          .from('chat_messages')
          .select('sender_alias, text, reply_to_alias, reply_to_text')
          .or(
            'and(sender_alias.eq.$meEscaped,peer_alias.eq.$peerEscaped),'
            'and(sender_alias.eq.$peerEscaped,peer_alias.eq.$meEscaped)',
          )
          .order('created_at', ascending: true) as List<dynamic>;
    }

    return rows.map((raw) {
      final row = raw as Map<String, dynamic>;
      final sender = (row['sender_alias'] as String?)?.trim();
      final text = (row['text'] as String?)?.trim();

      return ChatMessage(
        fromAlias: (sender == null || sender.isEmpty) ? 'Unknown' : sender,
        text: (text == null || text.isEmpty) ? '...' : text,
        isMe: sender == myAlias,
        replyToAlias: row['reply_to_alias'] as String?,
        replyToText: row['reply_to_text'] as String?,
      );
    }).toList(growable: false);
  }

  @override
  Future<void> sendMessage({
    String? groupId,
    String? peerAlias,
    required String message,
    String? replyToAlias,
    String? replyToText,
  }) async {
    final hasGroup = groupId != null && groupId.isNotEmpty;
    final hasPeer = peerAlias != null && peerAlias.isNotEmpty;
    if (hasGroup == hasPeer) {
      throw const PostgrestException(
        message: 'Exactly one of groupId or peerAlias is required.',
      );
    }

    final text = message.trim();
    if (text.isEmpty) {
      throw const PostgrestException(message: 'Message cannot be empty.');
    }

    final senderAlias = await _profiles.aliasForCurrentUser();
    await _client.from('chat_messages').insert(<String, dynamic>{
      'group_id': hasGroup ? groupId : null,
      'peer_alias': hasPeer ? peerAlias : null,
      'sender_alias': senderAlias,
      'text': text,
      'reply_to_alias': replyToAlias,
      'reply_to_text': replyToText,
    });
  }

  Future<Map<String, dynamic>?> _findGroup(String input) async {
    final byCode = await _client
        .from('community_groups')
        .select('id, name, code, weekly_change_percent')
        .eq('code', input)
        .maybeSingle();
    if (byCode != null) {
      return byCode;
    }

    return await _client
        .from('community_groups')
        .select('id, name, code, weekly_change_percent')
        .eq('id', input)
        .maybeSingle();
  }

  Future<List<CommunityMember>> _fetchGroupMembers(String groupId) async {
    final rows = await _client
        .from('community_group_members')
        .select('alias, streak_days')
        .eq('group_id', groupId)
        .order('streak_days', ascending: false) as List<dynamic>;

    return rows.map((raw) {
      final row = raw as Map<String, dynamic>;
      return CommunityMember(
        alias: (row['alias'] as String?)?.trim() ?? 'Unknown',
        streakDays: _toInt(row['streak_days'], fallback: 0),
      );
    }).toList(growable: false);
  }

  int _minutesAgo(dynamic rawCreatedAt) {
    if (rawCreatedAt is! String) {
      return 0;
    }
    final parsed = DateTime.tryParse(rawCreatedAt);
    if (parsed == null) {
      return 0;
    }
    final diff = DateTime.now().toUtc().difference(parsed.toUtc()).inMinutes;
    if (diff < 0) return 0;
    return diff;
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  CommunityPost _postFromRow(Map<String, dynamic> row) {
    final id = _toInt(row['id'], fallback: 0);
    final alias = (row['alias'] as String?)?.trim();
    final message = (row['message'] as String?)?.trim();

    final kindRaw = row['kind'] as String?;
    final topic = (row['topic'] as String?)?.trim();
    final label = (row['label'] as String?)?.trim();

    return CommunityPost(
      id: id,
      kind: CommunityPostKindX.fromId(kindRaw),
      alias: (alias == null || alias.isEmpty) ? 'Unknown' : alias,
      streakDays: _toInt(row['streak_days'], fallback: 0),
      topic: (topic == null || topic.isEmpty) ? null : topic,
      label: (label == null || label.isEmpty) ? null : label,
      message:
          (message == null || message.isEmpty) ? 'Shared an update.' : message,
      minutesAgo: _minutesAgo(row['created_at']),
      supportCount: _toInt(row['support_count'], fallback: 0),
      commentCount: _toInt(row['comment_count'], fallback: 0),
    );
  }

  bool _looksLikeMissingColumn(PostgrestException error) {
    final message = error.message.toLowerCase();
    return message.contains('column') && message.contains('does not exist');
  }

  bool _looksLikeMissingRelation(PostgrestException error, String relation) {
    final message = error.message.toLowerCase();
    final normalized = relation.toLowerCase();
    final code = error.code?.toLowerCase();
    if (code == '42p01') return true;
    return message.contains(normalized) && message.contains('does not exist');
  }

  CommunityPostReply _replyFromRow(Map<String, dynamic> row) {
    final id = _toInt(row['id'], fallback: 0);
    final postId = _toInt(row['post_id'], fallback: 0);
    final alias = (row['alias'] as String?)?.trim();
    final message = (row['message'] as String?)?.trim();

    return CommunityPostReply(
      id: id,
      postId: postId,
      alias: (alias == null || alias.isEmpty) ? 'Unknown' : alias,
      streakDays: _toInt(row['streak_days'], fallback: 0),
      message: (message == null || message.isEmpty) ? '...' : message,
      minutesAgo: _minutesAgo(row['created_at']),
      supportCount: _toInt(row['support_count'], fallback: 0),
    );
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[_random.nextInt(chars.length)]);
    }
    return buffer.toString();
  }

  String _escapeFilterValue(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(',', r'\,')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}
