class Badge {
  const Badge({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.criteria,
    this.category = 'milestone', // 'milestone', 'streak', 'challenge', 'social'
    this.rarity = 'common', // 'common', 'rare', 'epic', 'legendary'
    this.earnedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? icon; // emoji or icon name
  final String? criteria;
  final String category;
  final String rarity;
  final DateTime? earnedAt;

  bool get isEarned => earnedAt != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'criteria': criteria,
      'category': category,
      'rarity': rarity,
      'earned_at': earnedAt?.toIso8601String(),
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'].toString(),
      name: (json['name'] as String?) ?? 'Badge',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      criteria: json['criteria'] as String?,
      category: (json['category'] as String?) ?? 'milestone',
      rarity: (json['rarity'] as String?) ?? 'common',
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'] as String)
          : null,
    );
  }

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? criteria,
    String? category,
    String? rarity,
    DateTime? earnedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      criteria: criteria ?? this.criteria,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      earnedAt: earnedAt ?? this.earnedAt,
    );
  }

  @override
  String toString() {
    return 'Badge(name: $name, earned: $isEarned, rarity: $rarity)';
  }
}

// Predefined badge library
class BadgeLibrary {
  static const List<Badge> allBadges = <Badge>[
    // Milestone badges
    Badge(
      id: 'first_day',
      name: 'Fresh Start',
      description: 'Completed your first day sober',
      icon: '🌅',
      criteria: '1 day sober',
      category: 'milestone',
      rarity: 'common',
    ),
    Badge(
      id: 'one_week',
      name: 'Week Warrior',
      description: 'Maintained 7 days sober',
      icon: '💪',
      criteria: '7 days sober',
      category: 'milestone',
      rarity: 'common',
    ),
    Badge(
      id: 'one_month',
      name: 'Month Master',
      description: 'Reached 30 days clean',
      icon: '🌕',
      criteria: '30 days sober',
      category: 'milestone',
      rarity: 'rare',
    ),
    Badge(
      id: 'three_months',
      name: 'Quarter Champion',
      description: 'Made it through 90 days',
      icon: '🏆',
      criteria: '90 days sober',
      category: 'milestone',
      rarity: 'rare',
    ),
    Badge(
      id: 'six_months',
      name: 'Six-Month Hero',
      description: 'Six months strong and sober',
      icon: '⭐',
      criteria: '180 days sober',
      category: 'milestone',
      rarity: 'epic',
    ),
    Badge(
      id: 'one_year',
      name: 'Year Legend',
      description: 'Complete one year free',
      icon: '👑',
      criteria: '365 days sober',
      category: 'milestone',
      rarity: 'legendary',
    ),
    // Streak badges
    Badge(
      id: 'daily_keeper',
      name: 'Daily Keeper',
      description: 'Log in 10 days in a row',
      icon: '📱',
      criteria: '10-day login streak',
      category: 'streak',
      rarity: 'common',
    ),
    Badge(
      id: 'consistency_king',
      name: 'Consistency King',
      description: 'Journal 30 days straight',
      icon: '📝',
      criteria: '30-day journal streak',
      category: 'streak',
      rarity: 'rare',
    ),
    // Challenge badges
    Badge(
      id: 'focus_master',
      name: 'Focus Master',
      description: 'Complete 10 focus sessions',
      icon: '🧘',
      criteria: '10 focus sessions',
      category: 'challenge',
      rarity: 'common',
    ),
    Badge(
      id: 'crisis_survivor',
      name: 'Crisis Survivor',
      description: 'Use Emergency SOS 5 times successfully',
      icon: '🆘',
      criteria: '5 SOS uses',
      category: 'challenge',
      rarity: 'epic',
    ),
    // Social badges
    Badge(
      id: 'support_network',
      name: 'Connection Builder',
      description: 'Add 3 people to support network',
      icon: '🤝',
      criteria: '3 support contacts',
      category: 'social',
      rarity: 'rare',
    ),
    Badge(
      id: 'community_voice',
      name: 'Community Voice',
      description: 'Create 5 community posts',
      icon: '💬',
      criteria: '5 posts',
      category: 'social',
      rarity: 'rare',
    ),
  ];

  static Badge? findBadgeById(String id) {
    try {
      return allBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }
}
