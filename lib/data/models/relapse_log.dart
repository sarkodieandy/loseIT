class RelapseLog {
  const RelapseLog({
    required this.id,
    required this.userId,
    required this.relapseDate,
    this.note,
    this.createdAt,
  });

  final String id;
  final String userId;
  final DateTime relapseDate;
  final String? note;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'relapse_date': relapseDate.toIso8601String(),
      'note': note,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory RelapseLog.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return RelapseLog(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      relapseDate: parseDate(json['relapse_date'] ?? json['created_at']),
      note: json['note'] as String?,
      createdAt: json['created_at'] == null ? null : parseDate(json['created_at']),
    );
  }
}
