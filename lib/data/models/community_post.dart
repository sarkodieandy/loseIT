class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.userId,
    required this.anonymousName,
    required this.content,
    required this.likes,
    required this.reactionStrength,
    required this.reactionCelebrate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String anonymousName;
  final String content;
  final int likes;
  final int reactionStrength;
  final int reactionCelebrate;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'anonymous_name': anonymousName,
      'content': content,
      'likes': likes,
      'reaction_strength': reactionStrength,
      'reaction_celebrate': reactionCelebrate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return CommunityPost(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      anonymousName:
          (json['anonymous_name'] as String?) ?? (json['alias'] as String?) ?? 'SoberFriend',
      content: (json['content'] as String?) ?? (json['message'] as String?) ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      reactionStrength: (json['reaction_strength'] as num?)?.toInt() ?? 0,
      reactionCelebrate: (json['reaction_celebrate'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at']),
    );
  }
}
