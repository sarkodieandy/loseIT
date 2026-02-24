class CommunityUserBadge {
  const CommunityUserBadge({
    required this.id,
    required this.userId,
    required this.badgeType,
    this.verifiedBy,
    required this.verifiedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String
      badgeType; // 'verified_sponsor', 'verified_counselor', 'trusted_voice'
  final String? verifiedBy;
  final DateTime verifiedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'badge_type': badgeType,
        'verified_by': verifiedBy,
        'verified_at': verifiedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory CommunityUserBadge.fromJson(Map<String, dynamic> json) =>
      CommunityUserBadge(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        badgeType: (json['badge_type'] as String?) ?? '',
        verifiedBy:
            json['verified_by'] != null ? json['verified_by'].toString() : null,
        verifiedAt: DateTime.parse(json['verified_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
