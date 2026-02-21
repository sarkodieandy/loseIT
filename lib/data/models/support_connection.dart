class SupportConnection {
  const SupportConnection({
    required this.id,
    required this.userId,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.relationship,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? relationship;
  final bool isActive;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'relationship': relationship,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SupportConnection.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.parse(value).toLocal();
      }
      return DateTime.now();
    }

    return SupportConnection(
      id: json['id'].toString(),
      userId: json['user_id']?.toString() ?? '',
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      relationship: json['relationship'] as String?,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: parseDate(json['created_at']),
    );
  }
}
