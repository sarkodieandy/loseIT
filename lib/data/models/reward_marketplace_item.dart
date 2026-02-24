class RewardMarketplaceItem {
  const RewardMarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.category,
    this.externalLink,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String category; // 'physical', 'wellness', 'entertainment', 'charity'
  final String? externalLink;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'points_required': pointsRequired,
        'category': category,
        'external_link': externalLink,
        'image_url': imageUrl,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory RewardMarketplaceItem.fromJson(Map<String, dynamic> json) =>
      RewardMarketplaceItem(
        id: json['id'].toString(),
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        pointsRequired: (json['points_required'] as num?)?.toInt() ?? 0,
        category: (json['category'] as String?) ?? '',
        externalLink: json['external_link'] as String?,
        imageUrl: json['image_url'] as String?,
        isActive: (json['is_active'] as bool?) ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
