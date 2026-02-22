class UrgeLog {
  const UrgeLog({
    required this.id,
    required this.userId,
    this.habitId,
    required this.intensity,
    this.trigger,
    this.note,
    required this.occurredAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? habitId;
  final int intensity; // 1-10
  final String? trigger;
  final String? note;
  final DateTime occurredAt;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'habit_id': habitId,
      'intensity': intensity,
      'trigger': trigger,
      'note': note,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory UrgeLog.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return UrgeLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      habitId: json['habit_id']?.toString(),
      intensity: (json['intensity'] as num?)?.toInt() ?? 5,
      trigger: json['trigger'] as String?,
      note: json['note'] as String?,
      occurredAt: parseDate(json['occurred_at'] ?? json['created_at']),
      createdAt: json['created_at'] == null ? null : parseDate(json['created_at']),
    );
  }
}

