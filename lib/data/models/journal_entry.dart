class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.userId,
    required this.entryDate,
    required this.content,
    this.mood,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime entryDate;
  final String content;
  final String? mood;
  final String? photoUrl;
  final DateTime? createdAt;

  String get preview {
    final trimmed = content.trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 80)}…';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'entry_date': entryDate.toIso8601String(),
      'content': content,
      'mood': mood,
      'photo_url': photoUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return JournalEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      entryDate: parseDate(json['entry_date'] ?? json['created_at']),
      content: (json['content'] as String?) ?? '',
      mood: json['mood'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] == null ? null : parseDate(json['created_at']),
    );
  }
}
