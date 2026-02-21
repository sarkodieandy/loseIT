import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/user_habit.dart';

class HabitsRepository {
  HabitsRepository(this._client);

  final SupabaseClient _client;

  Future<List<UserHabit>> fetchHabits({bool activeOnly = true}) async {
    final user = _client.auth.currentUser;
    if (user == null) return const <UserHabit>[];

    try {
      final rows = await _client
          .from('user_habits')
          .select()
          .eq('user_id', user.id)
          .order('created_at') as List<dynamic>;

      final habits = rows
          .map((row) => UserHabit.fromJson(Map<String, dynamic>.from(row as Map)))
          .where((habit) => !activeOnly || habit.isActive)
          .toList(growable: false);
      return habits;
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('habits.fetch', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('habits.fetch', error, stackTrace);
      rethrow;
    }
  }

  Future<UserHabit> createHabit(UserHabit habit) async {
    try {
      final payload = Map<String, dynamic>.from(habit.toJson());
      if (payload['id'] == null || (payload['id'] as String).isEmpty) {
        payload.remove('id');
      }
      final row =
          await _client.from('user_habits').insert(payload).select().single();
      return UserHabit.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error, stackTrace) {
      AppLogger.error('habits.create', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('habits.create', error, stackTrace);
      rethrow;
    }
  }

  Future<UserHabit> updateHabit(UserHabit habit) async {
    final row = await _client
        .from('user_habits')
        .update(habit.toJson())
        .eq('id', habit.id)
        .select()
        .single();
    return UserHabit.fromJson(Map<String, dynamic>.from(row));
  }
}
