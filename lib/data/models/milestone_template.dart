class MilestoneTemplate {
  const MilestoneTemplate({
    required this.id,
    required this.title,
    required this.description,
    this.daysThreshold,
    this.targetValue,
    this.unit,
    this.badgeIconUrl,
    required this.rewardPoints,
    required this.isPremium,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final int? daysThreshold;
  final double? targetValue;
  final String? unit;
  final String? badgeIconUrl;
  final int rewardPoints;
  final bool isPremium;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'days_threshold': daysThreshold,
        'target_value': targetValue,
        'unit': unit,
        'badge_icon_url': badgeIconUrl,
        'reward_points': rewardPoints,
        'is_premium': isPremium,
        'created_at': createdAt.toIso8601String(),
      };

  factory MilestoneTemplate.fromJson(Map<String, dynamic> json) =>
      MilestoneTemplate(
        id: json['id'].toString(),
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        daysThreshold: json['days_threshold'] as int?,
        targetValue: (json['target_value'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        badgeIconUrl: json['badge_icon_url'] as String?,
        rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 10,
        isPremium: (json['is_premium'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
