import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/relapse_log.dart';

class RelapseRepository {
  RelapseRepository(this._client);

  final SupabaseClient _client;

  Future<RelapseLog> createLog({
    required DateTime relapseDate,
    String? note,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final payload = <String, dynamic>{
      'user_id': user.id,
      'relapse_date': relapseDate.toUtc().toIso8601String(),
      'note': note,
    };

    final row = await _client.from('relapse_logs').insert(payload).select().single();
    return RelapseLog.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<RelapseLog>> fetchLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <RelapseLog>[];

    final rows = await _client
        .from('relapse_logs')
        .select()
        .eq('user_id', user.id)
        .order('relapse_date', ascending: false)
        .limit(200) as List<dynamic>;

    return rows
        .map((row) => RelapseLog.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  }
}
