class SpendingLog {
  const SpendingLog({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.amount,
    this.description,
    required this.loggedDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? categoryId;
  final double amount;
  final String? description;
  final DateTime loggedDate;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'description': description,
        'logged_date': loggedDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory SpendingLog.fromJson(Map<String, dynamic> json) => SpendingLog(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        categoryId:
            json['category_id'] != null ? json['category_id'].toString() : null,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        description: json['description'] as String?,
        loggedDate: DateTime.parse(json['logged_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
