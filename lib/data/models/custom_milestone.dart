class CustomMilestone {
  const CustomMilestone({
    required this.id,
    required this.userId,
    required this.title,
    this.targetValue,
    this.currentValue,
    this.unit,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String title;
  final double? targetValue;
  final double? currentValue;
  final String? unit;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory CustomMilestone.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return CustomMilestone(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      title: (json['title'] as String?) ?? '',
      targetValue: (json['target_value'] as num?)?.toDouble(),
      currentValue: (json['current_value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      createdAt: parseDate(json['created_at']),
      completedAt:
          json['completed_at'] == null ? null : parseDate(json['completed_at']),
    );
  }
}
