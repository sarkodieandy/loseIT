import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/dm_message.dart';
import '../models/dm_thread.dart';

class DmRepository {
  DmRepository(this._client);

  final SupabaseClient _client;

  Stream<List<DmThread>> streamThreads() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream.value(const <DmThread>[]);
    }

    return _client
        .from('dm_threads')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((rows) => rows
            .map((row) => DmThread.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList(growable: false));
  }

  Future<DmThread?> fetchThread(String id) async {
    try {
      final row = await _client.from('dm_threads').select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return DmThread.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('dm.fetchThread', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('dm.fetchThread', error, stackTrace);
      rethrow;
    }
  }

  Future<DmThread> getOrCreateThread(String otherUserId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    if (otherUserId == user.id) {
      throw const AuthException('Cannot message yourself.');
    }

    try {
      final existing = await _client
          .from('dm_threads')
          .select()
          .or(
            'and(user_a.eq.${user.id},user_b.eq.$otherUserId),'
            'and(user_a.eq.$otherUserId,user_b.eq.${user.id})',
          )
          .maybeSingle();
      if (existing != null) {
        return DmThread.fromJson(Map<String, dynamic>.from(existing));
      }

      final payload = <String, dynamic>{
        'user_a': user.id,
        'user_b': otherUserId,
      };
      final created = await _client.from('dm_threads').insert(payload).select().single();
      return DmThread.fromJson(Map<String, dynamic>.from(created));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('dm.getOrCreateThread', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('dm.getOrCreateThread', error, stackTrace);
      rethrow;
    }
  }

  Stream<List<DmMessage>> streamMessages(String threadId) {
    return _client
        .from('dm_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .order('created_at')
        .map((rows) => rows
            .map((row) => DmMessage.fromJson(Map<String, dynamic>.from(row as Map)))
            .toList(growable: false));
  }

  Future<DmMessage> sendMessage({
    required String threadId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final payload = <String, dynamic>{
      'thread_id': threadId,
      'sender_id': user.id,
      'content': content,
    };

    try {
      final row = await _client.from('dm_messages').insert(payload).select().single();
      return DmMessage.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('dm.sendMessage', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('dm.sendMessage', error, stackTrace);
      rethrow;
    }
  }
}
