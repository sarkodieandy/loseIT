import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/theme_preference.dart';
import '../../features/onboarding/model/addiction_type.dart';
import '../../features/onboarding/model/onboarding_profile.dart';
import '../../features/onboarding/model/trigger_type.dart';
import '../app_state_repository.dart';

class SupabaseAppStateRepository implements AppStateRepository {
  SupabaseAppStateRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PersistedAppState?> load() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('user_settings')
        .select(
          'onboarding_complete, biometric_enabled, theme_preference, '
          'addiction_type, custom_addiction_label, frequency, severity, '
          'triggers, high_risk_slots, lock_mode, risk_alerts_enabled, '
          'daily_reminder_enabled, daily_reminder_minutes, last_reflection',
        )
        .eq('id', userId)
        .maybeSingle();

    if (row is! Map<String, dynamic>) {
      return null;
    }

    final addictionType =
        _enumFromName<AddictionType>(AddictionType.values, row['addiction_type']);
    final triggers = _stringSet(row['triggers'])
        .map((name) => _enumFromName<TriggerType>(TriggerType.values, name))
        .whereType<TriggerType>()
        .toSet();

    final highRiskSlots = _intSet(row['high_risk_slots'])
        .where((value) => value >= 0 && value <= 47)
        .toSet();

    final onboardingProfile = OnboardingProfile(
      addictionType: addictionType,
      customAddictionLabel: _toStringValue(row['custom_addiction_label']) ?? '',
      frequency: _toDouble(row['frequency'], fallback: 4).clamp(0, 10),
      severity: _toDouble(row['severity'], fallback: 5).clamp(0, 10),
      triggers: triggers,
      highRiskSlots: highRiskSlots,
      lockMode: _toBool(row['lock_mode'], fallback: false),
      riskAlertsEnabled: _toBool(row['risk_alerts_enabled'], fallback: true),
      dailyReminderEnabled:
          _toBool(row['daily_reminder_enabled'], fallback: true),
      dailyReminderMinutes: _toInt(row['daily_reminder_minutes'], fallback: 540)
          .clamp(0, 1439),
    );

    return PersistedAppState(
      onboardingComplete: _toBool(row['onboarding_complete'], fallback: false),
      biometricEnabled: _toBool(row['biometric_enabled'], fallback: false),
      themePreference: _themeFromString(row['theme_preference']),
      onboardingProfile: onboardingProfile,
      lastReflection: _toNullableTrimmedString(row['last_reflection']),
    );
  }

  @override
  Future<void> save({
    required bool onboardingComplete,
    required bool biometricEnabled,
    required ThemePreference themePreference,
    required OnboardingProfile onboardingProfile,
    required String? lastReflection,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('You must sign in before syncing app state.');
    }

    await _client.from('user_settings').upsert(
      <String, dynamic>{
        'id': userId,
        'onboarding_complete': onboardingComplete,
        'biometric_enabled': biometricEnabled,
        'theme_preference': themePreference.name,
        'addiction_type': onboardingProfile.addictionType?.name,
        'custom_addiction_label': onboardingProfile.customAddictionLabel.trim(),
        'frequency': onboardingProfile.frequency,
        'severity': onboardingProfile.severity,
        'triggers': onboardingProfile.triggers.map((t) => t.name).toList(),
        'high_risk_slots':
            onboardingProfile.highRiskSlots.toList()..sort((a, b) => a - b),
        'lock_mode': onboardingProfile.lockMode,
        'risk_alerts_enabled': onboardingProfile.riskAlertsEnabled,
        'daily_reminder_enabled': onboardingProfile.dailyReminderEnabled,
        'daily_reminder_minutes': onboardingProfile.dailyReminderMinutes,
        'last_reflection': _toNullableTrimmedString(lastReflection),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  ThemePreference _themeFromString(dynamic value) {
    final raw = _toStringValue(value);
    return _enumFromName<ThemePreference>(ThemePreference.values, raw) ??
        ThemePreference.system;
  }

  T? _enumFromName<T extends Enum>(List<T> values, dynamic rawName) {
    final name = _toStringValue(rawName);
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
      if (normalized == '1') return true;
      if (normalized == '0') return false;
    }
    return fallback;
  }

  int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  double _toDouble(dynamic value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  Set<String> _stringSet(dynamic value) {
    if (value is! List) return <String>{};
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Set<int> _intSet(dynamic value) {
    if (value is! List) return <int>{};
    return value
        .map((item) {
          if (item is int) return item;
          if (item is num) return item.toInt();
          if (item is String) return int.tryParse(item.trim());
          return null;
        })
        .whereType<int>()
        .toSet();
  }

  String? _toStringValue(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  String? _toNullableTrimmedString(dynamic value) {
    final parsed = _toStringValue(value);
    return parsed;
  }
}
