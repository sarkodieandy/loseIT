class NotificationPreferences {
  const NotificationPreferences({
    required this.id,
    required this.userId,
    required this.replyNotifications,
    required this.messageNotifications,
    required this.challengeUpdates,
    required this.milestoneCelebrations,
    required this.communityDigest,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final bool replyNotifications;
  final bool messageNotifications;
  final bool challengeUpdates;
  final bool milestoneCelebrations;
  final bool communityDigest;
  final String? quietHoursStart; // e.g., "22:00"
  final String? quietHoursEnd; // e.g., "08:00"
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'reply_notifications': replyNotifications,
        'message_notifications': messageNotifications,
        'challenge_updates': challengeUpdates,
        'milestone_celebrations': milestoneCelebrations,
        'community_digest': communityDigest,
        'quiet_hours_start': quietHoursStart,
        'quiet_hours_end': quietHoursEnd,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        replyNotifications: (json['reply_notifications'] as bool?) ?? true,
        messageNotifications: (json['message_notifications'] as bool?) ?? true,
        challengeUpdates: (json['challenge_updates'] as bool?) ?? true,
        milestoneCelebrations:
            (json['milestone_celebrations'] as bool?) ?? true,
        communityDigest: (json['community_digest'] as bool?) ?? false,
        quietHoursStart: json['quiet_hours_start'] as String?,
        quietHoursEnd: json['quiet_hours_end'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
