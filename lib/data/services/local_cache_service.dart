import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/journal_entry.dart';
import '../models/user_profile.dart';

class LocalCacheService {
  LocalCacheService._();

  static final LocalCacheService instance = LocalCacheService._();

  static const _settingsBoxName = 'be_sober_settings';
  static const _profileBoxName = 'be_sober_profile';
  static const _journalBoxName = 'be_sober_journal';

  late Box<dynamic> _settingsBox;
  late Box<dynamic> _profileBox;
  late Box<dynamic> _journalBox;

  Future<void> initialize() async {
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _profileBox = await Hive.openBox(_profileBoxName);
    _journalBox = await Hive.openBox(_journalBoxName);
  }

  Future<ThemeMode?> getThemeMode() async {
    final raw = _settingsBox.get('themeMode') as String?;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _settingsBox.put('themeMode', value);
  }

  Future<bool?> getOnboardingComplete() async {
    return _settingsBox.get('onboardingComplete') as bool?;
  }

  Future<void> setOnboardingComplete(bool value) async {
    await _settingsBox.put('onboardingComplete', value);
  }

  Future<UserProfile?> getCachedProfile() async {
    final data = _profileBox.get('profile');
    if (data is Map<dynamic, dynamic>) {
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> cacheProfile(UserProfile profile) async {
    await _profileBox.put('profile', profile.toJson());
  }

  Future<List<JournalEntry>> getCachedJournalEntries() async {
    final data = _journalBox.get('entries');
    if (data is List) {
      return data
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    }
    return const <JournalEntry>[];
  }

  Future<void> cacheJournalEntries(List<JournalEntry> entries) async {
    await _journalBox.put('entries', entries.map((e) => e.toJson()).toList());
  }

  String _groupChatLastSeenKey({
    required String userId,
    required String groupId,
  }) {
    return 'groupChatLastSeen:$userId:$groupId';
  }

  Future<DateTime?> getGroupChatLastSeen({
    required String userId,
    required String groupId,
  }) async {
    final raw = _settingsBox.get(_groupChatLastSeenKey(
      userId: userId,
      groupId: groupId,
    ));

    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
    }

    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.isUtc ? parsed : parsed.toUtc();
    }

    return null;
  }

  Future<void> setGroupChatLastSeen({
    required String userId,
    required String groupId,
    required DateTime seenAt,
  }) async {
    await _settingsBox.put(
      _groupChatLastSeenKey(userId: userId, groupId: groupId),
      seenAt.toUtc().millisecondsSinceEpoch,
    );
  }

  Future<void> clearGroupChatLastSeen({
    required String userId,
    required String groupId,
  }) async {
    await _settingsBox.delete(
      _groupChatLastSeenKey(userId: userId, groupId: groupId),
    );
  }
}
