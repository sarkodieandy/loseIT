import 'package:flutter/foundation.dart';

import 'addiction_type.dart';
import 'trigger_type.dart';

@immutable
class OnboardingProfile {
  final AddictionType? addictionType;
  final String customAddictionLabel;

  /// 0–10 (higher means more frequent).
  final double frequency;

  /// 0–10 (higher means more severe).
  final double severity;

  final Set<TriggerType> triggers;

  /// 48 slots of 30 minutes: `[0..47]`.
  final Set<int> highRiskSlots;

  final bool lockMode;
  final bool riskAlertsEnabled;
  final bool dailyReminderEnabled;

  /// Minutes since midnight (0..1439).
  final int dailyReminderMinutes;

  const OnboardingProfile({
    required this.addictionType,
    required this.customAddictionLabel,
    required this.frequency,
    required this.severity,
    required this.triggers,
    required this.highRiskSlots,
    required this.lockMode,
    required this.riskAlertsEnabled,
    required this.dailyReminderEnabled,
    required this.dailyReminderMinutes,
  });

  factory OnboardingProfile.initial() {
    return const OnboardingProfile(
      addictionType: null,
      customAddictionLabel: '',
      frequency: 4,
      severity: 5,
      triggers: <TriggerType>{},
      highRiskSlots: <int>{},
      lockMode: false,
      riskAlertsEnabled: true,
      dailyReminderEnabled: true,
      dailyReminderMinutes: 540,
    );
  }

  String get addictionLabel {
    final type = addictionType;
    if (type == null) return 'Discipline';
    if (type != AddictionType.custom) return type.label;
    if (customAddictionLabel.trim().isNotEmpty)
      return customAddictionLabel.trim();
    return 'Custom';
  }

  OnboardingProfile copyWith({
    AddictionType? addictionType,
    String? customAddictionLabel,
    double? frequency,
    double? severity,
    Set<TriggerType>? triggers,
    Set<int>? highRiskSlots,
    bool? lockMode,
    bool? riskAlertsEnabled,
    bool? dailyReminderEnabled,
    int? dailyReminderMinutes,
  }) {
    return OnboardingProfile(
      addictionType: addictionType ?? this.addictionType,
      customAddictionLabel: customAddictionLabel ?? this.customAddictionLabel,
      frequency: frequency ?? this.frequency,
      severity: severity ?? this.severity,
      triggers: triggers ?? this.triggers,
      highRiskSlots: highRiskSlots ?? this.highRiskSlots,
      lockMode: lockMode ?? this.lockMode,
      riskAlertsEnabled: riskAlertsEnabled ?? this.riskAlertsEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderMinutes: dailyReminderMinutes ?? this.dailyReminderMinutes,
    );
  }
}
