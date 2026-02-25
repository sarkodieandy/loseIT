class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    this.messageType = 'text',
    required this.content,
    this.attachmentPath,
    this.attachmentName,
    this.attachmentMime,
    this.attachmentSize,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String senderId;
  final String messageType;
  final String content;
  final String? attachmentPath;
  final String? attachmentName;
  final String? attachmentMime;
  final int? attachmentSize;
  final DateTime createdAt;

  bool get isFile => messageType == 'file' && attachmentPath != null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'message_type': messageType,
      'content': content,
      'attachment_path': attachmentPath,
      'attachment_name': attachmentName,
      'attachment_mime': attachmentMime,
      'attachment_size': attachmentSize,
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
      messageType: (json['message_type'] as String?) ?? 'text',
      content: (json['content'] as String?) ?? '',
      attachmentPath: json['attachment_path']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      attachmentMime: json['attachment_mime']?.toString(),
      attachmentSize: (json['attachment_size'] as num?)?.toInt(),
      createdAt: parseDate(json['created_at']),
    );
  }
}
