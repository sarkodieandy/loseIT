class CravingLog {
  const CravingLog({
    required this.id,
    required this.userId,
    this.habitId,
    required this.intensity,
    this.trigger,
    this.copingStrategyUsed,
    this.wasSuccessful,
    this.durationMinutes,
    this.notes,
    required this.loggedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? habitId;
  final int intensity; // 1-10 scale
  final String? trigger;
  final String? copingStrategyUsed;
  final bool? wasSuccessful;
  final int? durationMinutes;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'habit_id': habitId,
        'intensity': intensity,
        'trigger': trigger,
        'coping_strategy_used': copingStrategyUsed,
        'was_successful': wasSuccessful,
        'duration_minutes': durationMinutes,
        'notes': notes,
        'logged_at': loggedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory CravingLog.fromJson(Map<String, dynamic> json) => CravingLog(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        habitId: json['habit_id'] != null ? json['habit_id'].toString() : null,
        intensity: json['intensity'] as int? ?? 5,
        trigger: json['trigger'] as String?,
        copingStrategyUsed: json['coping_strategy_used'] as String?,
        wasSuccessful: json['was_successful'] as bool?,
        durationMinutes: json['duration_minutes'] as int?,
        notes: json['notes'] as String?,
        loggedAt: DateTime.parse(json['logged_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
