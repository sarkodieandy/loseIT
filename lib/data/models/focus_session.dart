class FocusSession {
  const FocusSession({
    required this.id,
    required this.userId,
    required this.sessionName,
    required this.durationMinutes,
    required this.pointsEarned,
    required this.startedAt,
    this.endedAt,
    required this.completed,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String sessionName;
  final int durationMinutes;
  final int pointsEarned;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool completed;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'session_name': sessionName,
        'duration_minutes': durationMinutes,
        'points_earned': pointsEarned,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'completed': completed,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        sessionName: (json['session_name'] as String?) ?? '',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
        pointsEarned: (json['points_earned'] as num?)?.toInt() ?? 0,
        startedAt: DateTime.parse(json['started_at'] as String),
        endedAt: json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        completed: (json['completed'] as bool?) ?? false,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
