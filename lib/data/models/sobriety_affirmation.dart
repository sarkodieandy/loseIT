class SobrietyAffirmation {
  const SobrietyAffirmation({
    required this.id,
    required this.userId,
    required this.affirmationText,
    this.category,
    required this.isCustom,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String affirmationText;
  final String? category; // 'motivation', 'strength', 'healing'
  final bool isCustom;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'affirmation_text': affirmationText,
        'category': category,
        'is_custom': isCustom,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory SobrietyAffirmation.fromJson(Map<String, dynamic> json) =>
      SobrietyAffirmation(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        affirmationText: (json['affirmation_text'] as String?) ?? '',
        category: json['category'] as String?,
        isCustom: (json['is_custom'] as bool?) ?? true,
        isActive: (json['is_active'] as bool?) ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
