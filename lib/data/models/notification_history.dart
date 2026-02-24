class NotificationHistory {
  const NotificationHistory({
    required this.id,
    required this.userId,
    required this.notificationType,
    this.triggeredByUser,
    this.relatedId,
    required this.title,
    required this.body,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String notificationType; // 'reply', 'message', 'challenge', 'milestone'
  final String? triggeredByUser;
  final String? relatedId;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'notification_type': notificationType,
        'triggered_by_user': triggeredByUser,
        'related_id': relatedId,
        'title': title,
        'body': body,
        'is_read': isRead,
        'read_at': readAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory NotificationHistory.fromJson(Map<String, dynamic> json) =>
      NotificationHistory(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        notificationType: (json['notification_type'] as String?) ?? '',
        triggeredByUser: json['triggered_by_user'] != null
            ? json['triggered_by_user'].toString()
            : null,
        relatedId:
            json['related_id'] != null ? json['related_id'].toString() : null,
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        isRead: (json['is_read'] as bool?) ?? false,
        readAt: json['read_at'] != null
            ? DateTime.parse(json['read_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
