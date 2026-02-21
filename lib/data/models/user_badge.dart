class UserBadge {
  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
  });

  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'badge_id': badgeId,
      'earned_at': earnedAt.toIso8601String(),
    };
  }

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return UserBadge(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      badgeId: json['badge_id']?.toString() ?? '',
      earnedAt: parseDate(json['earned_at']),
    );
  }
}
