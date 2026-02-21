class MoodLog {
  const MoodLog({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    required this.loggedDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String mood;
  final String? note;
  final DateTime loggedDate;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'mood': mood,
      'note': note,
      'logged_date': loggedDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoodLog.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return MoodLog(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      mood: (json['mood'] as String?) ?? 'neutral',
      note: json['note'] as String?,
      loggedDate: parseDate(json['logged_date']),
      createdAt: parseDate(json['created_at']),
    );
  }
}
