import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/urge_log.dart';

class UrgeRepository {
  UrgeRepository(this._client);

  final SupabaseClient _client;

  Future<List<UrgeLog>> fetchLogs({int limit = 200}) async {
    final user = _client.auth.currentUser;
    if (user == null) return const <UrgeLog>[];

    try {
      final rows = await _client
          .from('urge_logs')
          .select()
          .eq('user_id', user.id)
          .order('occurred_at', ascending: false)
          .limit(limit) as List<dynamic>;
      return rows
          .map((row) => UrgeLog.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('urge.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('urge.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<UrgeLog> createLog({
    String? habitId,
    required int intensity,
    String? trigger,
    String? note,
    DateTime? occurredAt,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final safeIntensity = intensity.clamp(1, 10);
    final payload = <String, dynamic>{
      'user_id': user.id,
      'habit_id': habitId,
      'intensity': safeIntensity,
      'trigger': (trigger?.trim().isEmpty ?? true) ? null : trigger!.trim(),
      'note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
    };

    try {
      final row = await _client.from('urge_logs').insert(payload).select().single();
      return UrgeLog.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('urge.create', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('urge.create', error, stackTrace);
      rethrow;
    }
  }
}

