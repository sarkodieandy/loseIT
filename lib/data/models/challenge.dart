class Challenge {
  const Challenge({
    required this.id,
    required this.title,
    this.description,
    this.durationDays,
    this.badgeImageUrl,
    this.memberCount = 0,
    this.isActive = true,
    this.kind = 'group',
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final int? durationDays;
  final String? badgeImageUrl;
  final int memberCount;
  final bool isActive;
  final String kind;
  final String? createdBy;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'duration_days': durationDays,
      'badge_image_url': badgeImageUrl,
      'member_count': memberCount,
      'is_active': isActive,
      'kind': kind,
      'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return null;
    }

    return Challenge(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? 'Challenge',
      description: json['description'] as String?,
      durationDays: (json['duration_days'] as num?)?.toInt(),
      badgeImageUrl: json['badge_image_url'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      kind: (json['kind'] as String?) ?? 'group',
      createdBy: json['created_by']?.toString(),
      createdAt: parseDate(json['created_at']),
    );
  }
}
