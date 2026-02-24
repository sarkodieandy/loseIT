class CopingStrategy {
  const CopingStrategy({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.durationMinutes,
    this.instructions,
    required this.isPremium,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String category; // 'breathing', 'grounding', 'distraction', 'movement'
  final int? durationMinutes;
  final String? instructions;
  final bool isPremium;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'duration_minutes': durationMinutes,
        'instructions': instructions,
        'is_premium': isPremium,
        'created_at': createdAt.toIso8601String(),
      };

  factory CopingStrategy.fromJson(Map<String, dynamic> json) => CopingStrategy(
        id: json['id'].toString(),
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        category: (json['category'] as String?) ?? '',
        durationMinutes: json['duration_minutes'] as int?,
        instructions: json['instructions'] as String?,
        isPremium: (json['is_premium'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
