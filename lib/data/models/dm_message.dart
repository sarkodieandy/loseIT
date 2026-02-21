class DmMessage {
  const DmMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'thread_id': threadId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory DmMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return DmMessage(
      id: json['id'].toString(),
      threadId: json['thread_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: (json['content'] as String?) ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }
}
