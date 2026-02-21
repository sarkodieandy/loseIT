import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/mood_log.dart';

class MoodRepository {
  MoodRepository(this._client);

  final SupabaseClient _client;

  Future<List<MoodLog>> fetchLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <MoodLog>[];

    try {
      final rows = await _client
          .from('mood_logs')
          .select()
          .eq('user_id', user.id)
          .order('logged_date', ascending: false) as List<dynamic>;
      return rows
          .map((row) => MoodLog.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('mood.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('mood.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<MoodLog> createLog({
    required String mood,
    String? note,
    DateTime? loggedDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final payload = <String, dynamic>{
      'user_id': user.id,
      'mood': mood,
      'note': note,
      'logged_date': (loggedDate ?? DateTime.now()).toIso8601String(),
    };

    try {
      final row = await _client.from('mood_logs').insert(payload).select().single();
      return MoodLog.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('mood.create', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('mood.create', error, stackTrace);
      rethrow;
    }
  }
}
