class MorningEveningRoutine {
  const MorningEveningRoutine({
    required this.id,
    required this.userId,
    required this.routineType,
    required this.routineName,
    this.description,
    required this.scheduledTime,
    required this.isActive,
    required this.reminderEnabled,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String routineType; // 'morning' or 'evening'
  final String routineName;
  final String? description;
  final String scheduledTime; // e.g., "06:00:00"
  final bool isActive;
  final bool reminderEnabled;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'routine_type': routineType,
        'routine_name': routineName,
        'description': description,
        'scheduled_time': scheduledTime,
        'is_active': isActive,
        'reminder_enabled': reminderEnabled,
        'created_at': createdAt.toIso8601String(),
      };

  factory MorningEveningRoutine.fromJson(Map<String, dynamic> json) =>
      MorningEveningRoutine(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        routineType: (json['routine_type'] as String?) ?? '',
        routineName: (json['routine_name'] as String?) ?? '',
        description: json['description'] as String?,
        scheduledTime: (json['scheduled_time'] as String?) ?? '',
        isActive: (json['is_active'] as bool?) ?? true,
        reminderEnabled: (json['reminder_enabled'] as bool?) ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
