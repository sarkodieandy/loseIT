class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return GroupMessage(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }
}

