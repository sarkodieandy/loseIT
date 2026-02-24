class FinancialGoal {
  const FinancialGoal({
    required this.id,
    required this.userId,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    this.reason,
    this.targetDate,
    required this.isCompleted,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final String? reason;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  double get progress => (currentAmount / targetAmount * 100).clamp(0, 100);

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'goal_name': goalName,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'reason': reason,
        'target_date': targetDate?.toIso8601String(),
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory FinancialGoal.fromJson(Map<String, dynamic> json) => FinancialGoal(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        goalName: (json['goal_name'] as String?) ?? '',
        targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
        currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
        reason: json['reason'] as String?,
        targetDate: json['target_date'] != null
            ? DateTime.parse(json['target_date'] as String)
            : null,
        isCompleted: (json['is_completed'] as bool?) ?? false,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
