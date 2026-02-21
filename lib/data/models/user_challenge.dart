class UserChallenge {
  const UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    this.progress = 0,
    this.completed = false,
    required this.startedAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String challengeId;
  final int progress;
  final bool completed;
  final DateTime startedAt;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'progress': progress,
      'completed': completed,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return UserChallenge(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      challengeId: json['challenge_id']?.toString() ?? '',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as bool?) ?? false,
      startedAt: parseDate(json['started_at']),
      completedAt:
          json['completed_at'] == null ? null : parseDate(json['completed_at']),
    );
  }
}
