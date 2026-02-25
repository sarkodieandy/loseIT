import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/recovery_plan.dart';

class RecoveryPlanRepository {
  RecoveryPlanRepository(this._client);

  final SupabaseClient _client;

  Future<RecoveryPlan?> fetchPlan() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final row = await _client
          .from('recovery_plans')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (row == null) return null;
      return RecoveryPlan.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('recovery_plan.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('recovery_plan.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<RecoveryPlan> upsertPlan({
    required List<String> triggers,
    required List<String> warningSigns,
    required List<String> copingActions,
    required String? supportMessage,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final clean = RecoveryPlan(
      userId: user.id,
      triggers: _cleanList(triggers),
      warningSigns: _cleanList(warningSigns),
      copingActions: _cleanList(copingActions),
      supportMessage: supportMessage?.trim().isEmpty == true
          ? null
          : supportMessage?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final payload = clean.toUpsertJson()
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      final row = await _client
          .from('recovery_plans')
          .upsert(payload, onConflict: 'user_id')
          .select()
          .single();
      return RecoveryPlan.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('recovery_plan.upsert', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('recovery_plan.upsert', error, stackTrace);
      rethrow;
    }
  }

  static List<String> _cleanList(List<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final value in raw) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) out.add(trimmed);
    }
    return out;
  }
}

