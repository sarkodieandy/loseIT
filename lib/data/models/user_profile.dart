class UserProfile {
  const UserProfile({
    required this.id,
    required this.soberStartDate,
    required this.habitName,
    this.habitCustomName,
    this.dailySpend,
    this.dailyTimeSpent,
    this.motivationText,
    this.motivationPhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final DateTime soberStartDate;
  final String habitName;
  final String? habitCustomName;
  final double? dailySpend;
  final int? dailyTimeSpent;
  final String? motivationText;
  final String? motivationPhotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayHabitName {
    final trimmedCustom = habitCustomName?.trim();
    if (habitName.toLowerCase() == 'other' && trimmedCustom != null && trimmedCustom.isNotEmpty) {
      return trimmedCustom;
    }
    return habitName;
  }

  UserProfile copyWith({
    DateTime? soberStartDate,
    String? habitName,
    String? habitCustomName,
    double? dailySpend,
    int? dailyTimeSpent,
    String? motivationText,
    String? motivationPhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      soberStartDate: soberStartDate ?? this.soberStartDate,
      habitName: habitName ?? this.habitName,
      habitCustomName: habitCustomName ?? this.habitCustomName,
      dailySpend: dailySpend ?? this.dailySpend,
      dailyTimeSpent: dailyTimeSpent ?? this.dailyTimeSpent,
      motivationText: motivationText ?? this.motivationText,
      motivationPhotoUrl: motivationPhotoUrl ?? this.motivationPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'sober_start_date': soberStartDate.toIso8601String(),
      'habit_name': habitName,
      'habit_custom_name': habitCustomName,
      'daily_spend': dailySpend,
      'daily_time_spent': dailyTimeSpent,
      'motivation_text': motivationText,
      'motivation_photo_url': motivationPhotoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return UserProfile(
      id: json['id'] as String,
      soberStartDate: parseDate(json['sober_start_date']),
      habitName: (json['habit_name'] as String?) ?? 'Alcohol',
      habitCustomName: json['habit_custom_name'] as String?,
      dailySpend: (json['daily_spend'] as num?)?.toDouble(),
      dailyTimeSpent: (json['daily_time_spent'] as num?)?.toInt(),
      motivationText: json['motivation_text'] as String?,
      motivationPhotoUrl: json['motivation_photo_url'] as String?,
      createdAt: json['created_at'] == null ? null : parseDate(json['created_at']),
      updatedAt: json['updated_at'] == null ? null : parseDate(json['updated_at']),
    );
  }
}
