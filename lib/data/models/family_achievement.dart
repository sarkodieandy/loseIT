class FamilyAchievement {
  const FamilyAchievement({
    required this.id,
    required this.userId,
    required this.familyMemberName,
    required this.achievementTitle,
    this.description,
    required this.celebrationDate,
    required this.isShared,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String familyMemberName;
  final String achievementTitle;
  final String? description;
  final DateTime celebrationDate;
  final bool isShared;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'family_member_name': familyMemberName,
        'achievement_title': achievementTitle,
        'description': description,
        'celebration_date': celebrationDate.toIso8601String(),
        'is_shared': isShared,
        'created_at': createdAt.toIso8601String(),
      };

  factory FamilyAchievement.fromJson(Map<String, dynamic> json) =>
      FamilyAchievement(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        familyMemberName: (json['family_member_name'] as String?) ?? '',
        achievementTitle: (json['achievement_title'] as String?) ?? '',
        description: json['description'] as String?,
        celebrationDate: DateTime.parse(json['celebration_date'] as String),
        isShared: (json['is_shared'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
