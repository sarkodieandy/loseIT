class BackupSchedule {
  const BackupSchedule({
    required this.id,
    required this.userId,
    required this.backupFrequency,
    this.timeOfDay,
    required this.isEnabled,
    this.lastBackupAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String backupFrequency; // 'daily', 'weekly'
  final String? timeOfDay; // e.g., "02:00:00"
  final bool isEnabled;
  final DateTime? lastBackupAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'backup_frequency': backupFrequency,
        'time_of_day': timeOfDay,
        'is_enabled': isEnabled,
        'last_backup_at': lastBackupAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory BackupSchedule.fromJson(Map<String, dynamic> json) => BackupSchedule(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        backupFrequency: (json['backup_frequency'] as String?) ?? 'daily',
        timeOfDay: json['time_of_day'] as String?,
        isEnabled: (json['is_enabled'] as bool?) ?? true,
        lastBackupAt: json['last_backup_at'] != null
            ? DateTime.parse(json['last_backup_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
