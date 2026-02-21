class DmThread {
  const DmThread({
    required this.id,
    required this.userA,
    required this.userB,
    required this.createdAt,
    required this.lastMessageAt,
  });

  final String id;
  final String userA;
  final String userB;
  final DateTime createdAt;
  final DateTime lastMessageAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_a': userA,
      'user_b': userB,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
    };
  }

  factory DmThread.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return DmThread(
      id: json['id'].toString(),
      userA: json['user_a']?.toString() ?? '',
      userB: json['user_b']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
      lastMessageAt: parseDate(json['last_message_at']),
    );
  }
}
