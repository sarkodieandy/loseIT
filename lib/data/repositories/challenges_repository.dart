import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';

class ChallengesRepository {
  ChallengesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Challenge>> fetchChallenges({String kind = 'group'}) async {
    try {
      Future<List<dynamic>> runQuery({
        required bool includeKindFilter,
        required bool includeOrdering,
      }) async {
        dynamic query = _client.from('challenges').select().eq('is_active', true);
        if (includeKindFilter && kind.trim().isNotEmpty && kind != 'all') {
          query = query.eq('kind', kind);
        }
        if (includeOrdering) {
          query = query.order('member_count', ascending: false);
          query = query.order('created_at', ascending: false);
        }
        return await query as List<dynamic>;
      }

      List<dynamic> rows;
      try {
        rows = await runQuery(includeKindFilter: true, includeOrdering: true);
      } on PostgrestException catch (error) {
        final message = error.message;
        if (message.contains('column \"kind\"') ||
            message.contains('column \"member_count\"') ||
            message.contains('column \"created_at\"')) {
          rows = await runQuery(includeKindFilter: false, includeOrdering: false);
        } else {
          rethrow;
        }
      }
      return rows
          .map((row) => Challenge.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('challenges.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('challenges.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<List<UserChallenge>> fetchUserChallenges() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <UserChallenge>[];
    try {
      final rows = await _client
          .from('user_challenges')
          .select()
          .eq('user_id', user.id) as List<dynamic>;
      return rows
          .map((row) => UserChallenge.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('challenges.fetchUser', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('challenges.fetchUser', error, stackTrace);
      rethrow;
    }
  }

  Future<UserChallenge> startChallenge(String challengeId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    final payload = <String, dynamic>{
      'user_id': user.id,
      'challenge_id': challengeId,
      'progress': 0,
      'completed': false,
    };
    try {
      final row = await _client
          .from('user_challenges')
          .upsert(
            payload,
            onConflict: 'user_id,challenge_id',
          )
          .select()
          .single();
      return UserChallenge.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      final message = error.message;
      if (message.contains('no unique or exclusion constraint') ||
          message.contains('ON CONFLICT')) {
        final row = await _client
            .from('user_challenges')
            .insert(payload)
            .select()
            .single();
        return UserChallenge.fromJson(Map<String, dynamic>.from(row));
      }
      AppLogger.error('challenges.start', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('challenges.start', error, stackTrace);
      rethrow;
    }
  }

  Future<UserChallenge> updateProgress(UserChallenge challenge, int progress) async {
    final payload = <String, dynamic>{
      'progress': progress,
      'completed': challenge.completed,
    };
    final row = await _client
        .from('user_challenges')
        .update(payload)
        .eq('id', challenge.id)
        .select()
        .single();
    return UserChallenge.fromJson(Map<String, dynamic>.from(row));
  }

  Future<Challenge> createGroup({
    required String title,
    String? scheduleLabel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw Exception('Group name is empty.');
    }

    final trimmedLabel = scheduleLabel?.trim();

    final payload = <String, dynamic>{
      'title': trimmedTitle,
      if (trimmedLabel != null && trimmedLabel.isNotEmpty) 'description': trimmedLabel,
      'is_active': true,
      'kind': 'group',
      'created_by': user.id,
    };

    try {
      final row = await _client.from('challenges').insert(payload).select().single();
      final created = Challenge.fromJson(Map<String, dynamic>.from(row));
      await startChallenge(created.id); // creator joins automatically
      return created;
    } on PostgrestException catch (error, stackTrace) {
      final message = error.message;
      if (message.contains('column \"kind\"') ||
          message.contains('column \"created_by\"') ||
          message.contains('permission denied') ||
          message.contains('policy')) {
        AppLogger.error('groups.create', error, stackTrace);
      }
      // Fallback insert for older schemas (no kind/created_by).
      if (message.contains('column \"kind\"') ||
          message.contains('column \"created_by\"')) {
        final fallbackPayload = <String, dynamic>{
          'title': trimmedTitle,
          if (trimmedLabel != null && trimmedLabel.isNotEmpty) 'description': trimmedLabel,
          'is_active': true,
        };
        final row = await _client
            .from('challenges')
            .insert(fallbackPayload)
            .select()
            .single();
        final created = Challenge.fromJson(Map<String, dynamic>.from(row));
        await startChallenge(created.id);
        return created;
      }

      AppLogger.error('groups.create', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('groups.create', error, stackTrace);
      rethrow;
    }
  }

  Future<void> leaveGroup(String groupId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');
    try {
      await _client
          .from('user_challenges')
          .delete()
          .eq('user_id', user.id)
          .eq('challenge_id', groupId);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('groups.leave', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('groups.leave', error, stackTrace);
      rethrow;
    }
  }
}
