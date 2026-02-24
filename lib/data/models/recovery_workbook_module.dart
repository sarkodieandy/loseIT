class RecoveryWorkbookModule {
  const RecoveryWorkbookModule({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.moduleType,
    required this.orderIndex,
    required this.isPremium,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String content;
  final String
      moduleType; // 'cbt', 'mindfulness', 'motivation', 'relapse_prevention'
  final int orderIndex;
  final bool isPremium;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'content': content,
        'module_type': moduleType,
        'order_index': orderIndex,
        'is_premium': isPremium,
        'created_at': createdAt.toIso8601String(),
      };

  factory RecoveryWorkbookModule.fromJson(Map<String, dynamic> json) =>
      RecoveryWorkbookModule(
        id: json['id'].toString(),
        title: (json['title'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        content: (json['content'] as String?) ?? '',
        moduleType: (json['module_type'] as String?) ?? '',
        orderIndex: json['order_index'] as int? ?? 0,
        isPremium: (json['is_premium'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
