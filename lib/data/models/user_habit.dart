class UserHabit {
  const UserHabit({
    required this.id,
    required this.userId,
    required this.habitName,
    required this.soberStartDate,
    this.habitCustomName,
    this.dailySpend,
    this.dailyTimeSpent,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String habitName;
  final String? habitCustomName;
  final DateTime soberStartDate;
  final double? dailySpend;
  final int? dailyTimeSpent;
  final bool isActive;
  final DateTime createdAt;

  String get displayName => habitCustomName?.trim().isNotEmpty == true
      ? habitCustomName!.trim()
      : habitName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'habit_name': habitName,
      'habit_custom_name': habitCustomName,
      'sober_start_date': soberStartDate.toIso8601String(),
      'daily_spend': dailySpend,
      'daily_time_spent': dailyTimeSpent,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserHabit.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return UserHabit(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      habitName: (json['habit_name'] as String?) ?? 'Habit',
      habitCustomName: json['habit_custom_name'] as String?,
      soberStartDate: parseDate(json['sober_start_date']),
      dailySpend: (json['daily_spend'] as num?)?.toDouble(),
      dailyTimeSpent: (json['daily_time_spent'] as num?)?.toInt(),
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: parseDate(json['created_at']),
    );
  }
}
