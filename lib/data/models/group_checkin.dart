class GroupCheckin {
  const GroupCheckin({
    required this.id,
    required this.groupId,
    required this.userId,
    this.note,
    required this.checkinDate,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String? note;
  final DateTime checkinDate;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'note': note,
      'checkin_date': checkinDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupCheckin.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return GroupCheckin(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      note: json['note'] as String?,
      checkinDate: parseDate(json['checkin_date']),
      createdAt: parseDate(json['created_at']),
    );
  }
}

