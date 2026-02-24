class ProgressWall {
  const ProgressWall({
    required this.id,
    required this.userId,
    required this.title,
    required this.milestonesReached,
    required this.totalMilestones,
    required this.progressPercentage,
    required this.isShareable,
    this.shareToken,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final int milestonesReached;
  final int totalMilestones;
  final double progressPercentage;
  final bool isShareable;
  final String? shareToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'milestones_reached': milestonesReached,
        'total_milestones': totalMilestones,
        'progress_percentage': progressPercentage,
        'is_shareable': isShareable,
        'share_token': shareToken,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ProgressWall.fromJson(Map<String, dynamic> json) => ProgressWall(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        title: (json['title'] as String?) ?? '',
        milestonesReached: (json['milestones_reached'] as num?)?.toInt() ?? 0,
        totalMilestones: (json['total_milestones'] as num?)?.toInt() ?? 0,
        progressPercentage:
            (json['progress_percentage'] as num?)?.toDouble() ?? 0,
        isShareable: (json['is_shareable'] as bool?) ?? true,
        shareToken: json['share_token'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
