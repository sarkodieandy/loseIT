import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/emergency_session.dart';

class EmergencySessionsRepository {
  EmergencySessionsRepository(this._client);

  final SupabaseClient _client;

  /// Save emergency SOS session to backend
  Future<bool> saveSession({
    required String sessionId,
    required String technique,
    required int durationSeconds,
    required bool completed,
    required bool contactedSupport,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client.from('emergency_sessions').insert({
        'user_id': user.id,
        'session_id': sessionId,
        'technique': technique,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'contacted_support': contactedSupport,
        'notes': notes,
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      });

      AppLogger.info('emergency_session.saved: $sessionId');
      return true;
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('emergency_session.save', error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('emergency_session.save', error, stackTrace);
      return false;
    }
  }

  /// Fetch user's emergency sessions
  Future<List<EmergencySession>> fetchSessions() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <EmergencySession>[];

    try {
      final rows = await _client
          .from('emergency_sessions')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false) as List<dynamic>;

      return rows.map((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return EmergencySession(
          id: map['id'] as String? ?? '',
          createdAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : DateTime.now(),
          type: map['technique'] as String? ?? 'breathing',
          durationSeconds: map['duration_seconds'] as int? ?? 0,
          completed: map['completed'] as bool? ?? false,
          contactedSupport: map['contacted_support'] as bool? ?? false,
          notes: map['notes'] as String?,
        );
      }).toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('emergency_sessions.fetch', error, stackTrace);
      return const <EmergencySession>[];
    } catch (error, stackTrace) {
      AppLogger.error('emergency_sessions.fetch', error, stackTrace);
      return const <EmergencySession>[];
    }
  }

  /// Update emergency session
  Future<bool> updateSession({
    required String sessionId,
    required int durationSeconds,
    required bool contactedSupport,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('emergency_sessions')
          .update({
            'duration_seconds': durationSeconds,
            'contacted_support': contactedSupport,
            'notes': notes,
            'completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('session_id', sessionId);

      AppLogger.info('emergency_session.updated: $sessionId');
      return true;
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('emergency_session.update', error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('emergency_session.update', error, stackTrace);
      return false;
    }
  }
}
