import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/custom_milestone.dart';

class MilestonesRepository {
  MilestonesRepository(this._client);

  final SupabaseClient _client;

  Future<List<CustomMilestone>> fetchMilestones() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <CustomMilestone>[];
    try {
      final rows = await _client
          .from('custom_milestones')
          .select()
          .eq('user_id', user.id)
          .order('created_at') as List<dynamic>;
      return rows
          .map((row) => CustomMilestone.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('milestones.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('milestones.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<CustomMilestone> createMilestone(CustomMilestone milestone) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    final payload = Map<String, dynamic>.from(milestone.toJson());
    payload['user_id'] = user.id;
    if ((payload['id'] as String?)?.isEmpty ?? true) {
      payload.remove('id');
    }
    final row = await _client
        .from('custom_milestones')
        .insert(payload)
        .select()
        .single();
    return CustomMilestone.fromJson(Map<String, dynamic>.from(row));
  }
}
