import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';

class BadgesRepository {
  BadgesRepository(this._client);

  final SupabaseClient _client;

  Future<List<Badge>> fetchBadges() async {
    try {
      final rows = await _client.from('badges').select() as List<dynamic>;
      return rows
          .map((row) => Badge.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('badges.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('badges.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<List<UserBadge>> fetchUserBadges() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <UserBadge>[];
    try {
      final rows = await _client
          .from('user_badges')
          .select()
          .eq('user_id', user.id) as List<dynamic>;
      return rows
          .map((row) => UserBadge.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('badges.fetchUser', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('badges.fetchUser', error, stackTrace);
      rethrow;
    }
  }
}
