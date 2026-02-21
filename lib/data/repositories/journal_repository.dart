import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/journal_entry.dart';
import '../services/local_cache_service.dart';

class JournalRepository {
  JournalRepository(this._client);

  final SupabaseClient _client;

  Future<List<JournalEntry>> fetchEntries() async {
    final user = _client.auth.currentUser;
    if (user == null) return const <JournalEntry>[];

    try {
      final rows = await _client
          .from('journal_entries')
          .select()
          .eq('user_id', user.id)
          .order('entry_date', ascending: false)
          .limit(200) as List<dynamic>;
      final entries = rows
          .map((row) => JournalEntry.fromJson(
                Map<String, dynamic>.from(row as Map),
              ))
          .toList(growable: false);
      await LocalCacheService.instance.cacheJournalEntries(entries);
      return entries;
    } catch (_) {
      return LocalCacheService.instance.getCachedJournalEntries();
    }
  }

  Future<JournalEntry> createEntry({
    required String content,
    required DateTime entryDate,
    String? mood,
    String? photoUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Not authenticated');

    final payload = <String, dynamic>{
      'user_id': user.id,
      'entry_date': entryDate.toUtc().toIso8601String(),
      'content': content,
      'mood': mood,
      'photo_url': photoUrl,
    };

    final row = await _client.from('journal_entries').insert(payload).select().single();
    return JournalEntry.fromJson(Map<String, dynamic>.from(row));
  }

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    final payload = entry.toJson();
    final row = await _client
        .from('journal_entries')
        .update(payload)
        .eq('id', entry.id)
        .select()
        .single();
    return JournalEntry.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> deleteEntry(String id) async {
    await _client.from('journal_entries').delete().eq('id', id);
  }

  Future<String> uploadPhoto(File file, {required String userId}) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final path = '$userId/$fileName';
    await _client.storage.from('journal-photos').upload(path, file);
    return _client.storage.from('journal-photos').getPublicUrl(path);
  }
}
