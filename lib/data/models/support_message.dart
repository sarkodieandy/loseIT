class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.connectionId,
    required this.senderId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String connectionId;
  final String senderId;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'connection_id': connectionId,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return SupportMessage(
      id: json['id'].toString(),
      connectionId: json['connection_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      message: (json['message'] as String?) ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }
}
