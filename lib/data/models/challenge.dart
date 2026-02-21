class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    this.description,
    this.durationDays,
    this.badgeImageUrl,
    this.memberCount = 0,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String? description;
  final int? durationDays;
  final String? badgeImageUrl;
  final int memberCount;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'duration_days': durationDays,
      'badge_image_url': badgeImageUrl,
      'member_count': memberCount,
      'is_active': isActive,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? 'Challenge',
      description: json['description'] as String?,
      durationDays: (json['duration_days'] as num?)?.toInt(),
      badgeImageUrl: json['badge_image_url'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
    );
  }
}
