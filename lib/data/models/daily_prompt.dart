class DailyPrompt {
  const DailyPrompt({
    required this.id,
    required this.promptText,
    this.category,
    this.isPremium = false,
  });

  final String id;
  final String promptText;
  final String? category;
  final bool isPremium;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'prompt_text': promptText,
      'category': category,
      'is_premium': isPremium,
    };
  }

  factory DailyPrompt.fromJson(Map<String, dynamic> json) {
    return DailyPrompt(
      id: json['id'].toString(),
      promptText: (json['prompt_text'] as String?) ?? '',
      category: json['category'] as String?,
      isPremium: (json['is_premium'] as bool?) ?? false,
    );
  }
}
