class CommunityReply {
  const CommunityReply({
    required this.id,
    required this.postId,
    required this.userId,
    required this.anonymousName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String userId;
  final String anonymousName;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'anonymous_name': anonymousName,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return CommunityReply(
      id: json['id'].toString(),
      postId: json['post_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      anonymousName:
          (json['anonymous_name'] as String?) ?? (json['alias'] as String?) ?? 'SoberFriend',
      content: (json['content'] as String?) ?? (json['message'] as String?) ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }
}
