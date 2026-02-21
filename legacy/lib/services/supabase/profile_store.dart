import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class SupabaseProfileStore {
  SupabaseProfileStore(this._client);

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  String _defaultAlias(String userId) {
    final compact = userId.replaceAll('-', '').toUpperCase();
    final suffix = compact.length > 6
        ? compact.substring(compact.length - 6)
        : compact.padLeft(6, '0');
    return 'Alias-$suffix';
  }

  Future<void> ensureProfileForCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return;
    final alias = _defaultAlias(userId);
    await _client.from('profiles').upsert(
      <String, dynamic>{
        'id': userId,
        'alias': alias,
        'is_premium': false,
        'streak_days': 0,
      },
      onConflict: 'id',
    );
  }

  Future<String> aliasForCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) {
      return 'Guest';
    }

    try {
      final row = await _client
          .from('profiles')
          .select('alias')
          .eq('id', userId)
          .maybeSingle();
      final alias = row?['alias'];
      if (alias is String && alias.trim().isNotEmpty) {
        return alias.trim();
      }
    } catch (error, stackTrace) {
      AppLogger.error('SupabaseProfileStore.aliasForCurrentUser.select', error,
          stackTrace);
    }

    final fallback = _defaultAlias(userId);
    try {
      await _client.from('profiles').upsert(
        <String, dynamic>{
          'id': userId,
          'alias': fallback,
          'is_premium': false,
        },
        onConflict: 'id',
      );
    } catch (error, stackTrace) {
      AppLogger.error('SupabaseProfileStore.aliasForCurrentUser.upsert', error,
          stackTrace);
    }
    return fallback;
  }

  Future<bool> isPremium() async {
    final userId = currentUserId;
    if (userId == null) {
      return false;
    }
    try {
      final row = await _client
          .from('profiles')
          .select('is_premium')
          .eq('id', userId)
          .maybeSingle();
      final value = row?['is_premium'];
      if (value is bool) return value;
      if (value is num) return value != 0;
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('SupabaseProfileStore.isPremium', error, stackTrace);
      return false;
    }
  }

  Future<void> setPremium(bool value) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const AuthException('You must sign in before updating premium.');
    }
    final alias = await aliasForCurrentUser();
    await _client.from('profiles').upsert(
      <String, dynamic>{
        'id': userId,
        'alias': alias,
        'is_premium': value,
      },
      onConflict: 'id',
    );
  }
}
