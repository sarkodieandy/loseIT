import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import '../services/local_cache_service.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<UserProfile?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) {
        return null;
      }
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(data));
      await LocalCacheService.instance.cacheProfile(profile);
      return profile;
    } catch (_) {
      return LocalCacheService.instance.getCachedProfile();
    }
  }

  Future<UserProfile> createProfile(UserProfile profile) async {
    final inserted = await _client.from('profiles').insert(profile.toJson()).select().single();
    final created = UserProfile.fromJson(Map<String, dynamic>.from(inserted));
    await LocalCacheService.instance.cacheProfile(created);
    return created;
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final payload = profile.toJson()..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final row = await _client.from('profiles').upsert(payload).select().single();
    final updated = UserProfile.fromJson(Map<String, dynamic>.from(row));
    await LocalCacheService.instance.cacheProfile(updated);
    return updated;
  }

  Future<String> uploadMotivationPhoto(File file, {required String userId}) async {
    final bucket = 'motivation-photos';
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final path = '$userId/$fileName';
    AppLogger.info(
      'Storage upload start bucket=$bucket path=$path size=${file.lengthSync()}',
    );
    try {
      await _client.storage.from(bucket).upload(path, file);
      final url = _client.storage.from(bucket).getPublicUrl(path);
      AppLogger.info('Storage upload success bucket=$bucket path=$path');
      return url;
    } on StorageException catch (error, stackTrace) {
      AppLogger.error('storage.upload.$bucket', error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('storage.upload.$bucket', error, stackTrace);
      rethrow;
    }
  }
}
