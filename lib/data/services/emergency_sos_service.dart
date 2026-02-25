import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/emergency_session.dart';

class EmergencySosService {
  EmergencySosService._();

  static final EmergencySosService instance = EmergencySosService._();

  final StreamController<EmergencySession> _sessionController =
      StreamController<EmergencySession>.broadcast();

  Stream<EmergencySession> get sessionStream => _sessionController.stream;

  /// Initiates emergency SOS with guided breathing or grounding
  Future<EmergencySession?> startEmergencySOS({
    required String technique, // 'breathing' or 'grounding'
  }) async {
    try {
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      AppLogger.info('emergency: SOS started, technique=$technique');

      final session = EmergencySession(
        id: sessionId,
        createdAt: DateTime.now(),
        type: technique,
        durationSeconds: 0,
        completed: false,
        contactedSupport: false,
      );

      if (!_sessionController.isClosed) {
        _sessionController.add(session);
      }

      // Best-effort persist start to Supabase backend.
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('emergency_sessions').insert({
            'user_id': user.id,
            'session_id': sessionId,
            'technique': technique,
            'duration_seconds': 0,
            'completed': false,
            'contacted_support': false,
            'notes': null,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        AppLogger.error('emergency.startSOS.persist', e, null);
      }

      return session;
    } catch (error, stackTrace) {
      AppLogger.error('emergency.startSOS', error, stackTrace);
      return null;
    }
  }

  /// Complete emergency session
  Future<void> completeSession({
    required String sessionId,
    required String technique,
    required int durationSeconds,
    required bool contactedSupport,
    String? notes,
  }) async {
    try {
      final session = EmergencySession(
        id: sessionId,
        createdAt: DateTime.now(),
        type: technique,
        durationSeconds: durationSeconds,
        completed: true,
        contactedSupport: contactedSupport,
        notes: notes,
      );

      AppLogger.info(
        'emergency: session complete (${durationSeconds}s, support=$contactedSupport)',
      );

      if (!_sessionController.isClosed) {
        _sessionController.add(session);
      }

      // Persist to Supabase backend
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('emergency_sessions').upsert({
            'user_id': user.id,
            'session_id': sessionId,
            'technique': technique,
            'duration_seconds': durationSeconds,
            'contacted_support': contactedSupport,
            'notes': notes,
            'completed': true,
            'completed_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,session_id');
        }
      } catch (e) {
        AppLogger.error('emergency: failed to persist session', e, null);
      }
    } catch (error, stackTrace) {
      AppLogger.error('emergency.completeSession', error, stackTrace);
    }
  }

  /// Log urge/emergency event
  Future<void> logUrgeTrigger({
    required String trigger, // 'stress', 'boredom', 'sleep_deprived', etc.
    required String intensity, // 'low', 'medium', 'high'
  }) async {
    try {
      AppLogger.info(
          'emergency: urge trigger logged, trigger=$trigger, intensity=$intensity');

      // Log to Supabase for analytics & ML model training
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          await client.from('urge_logs').insert({
            'user_id': user.id,
            'trigger': trigger,
            'intensity': intensity,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        AppLogger.error('emergency: failed to log urge', e, null);
      }
    } catch (error, stackTrace) {
      AppLogger.error('emergency.logUrge', error, stackTrace);
    }
  }

  void dispose() {
    _sessionController.close();
  }
}
