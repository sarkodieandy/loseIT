import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/challenge.dart';
import '../models/user_challenge.dart';

class ChallengesRepository {
  ChallengesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Challenge>> fetchChallenges() async {
    try {
      final rows = await _client
          .from('challenges')
          .select()
          .eq('is_active', true) as List<dynamic>;
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
    final row = await _client
        .from('user_challenges')
        .insert(payload)
        .select()
        .single();
    return UserChallenge.fromJson(Map<String, dynamic>.from(row));
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
}
