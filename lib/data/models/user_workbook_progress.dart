class UserWorkbookProgress {
  const UserWorkbookProgress({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.completed,
    this.completedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String moduleId;
  final bool completed;
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'module_id': moduleId,
        'completed': completed,
        'completed_at': completedAt?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserWorkbookProgress.fromJson(Map<String, dynamic> json) =>
      UserWorkbookProgress(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        moduleId: json['module_id'].toString(),
        completed: (json['completed'] as bool?) ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
