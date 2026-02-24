class EmergencySosContact {
  const EmergencySosContact({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    this.contactEmail,
    required this.isPrimary,
    required this.isActive,
    this.lastContactedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String contactName;
  final String contactPhone;
  final String? contactEmail;
  final bool isPrimary;
  final bool isActive;
  final DateTime? lastContactedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'is_primary': isPrimary,
        'is_active': isActive,
        'last_contacted_at': lastContactedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory EmergencySosContact.fromJson(Map<String, dynamic> json) =>
      EmergencySosContact(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        contactName: (json['contact_name'] as String?) ?? '',
        contactPhone: (json['contact_phone'] as String?) ?? '',
        contactEmail: json['contact_email'] as String?,
        isPrimary: (json['is_primary'] as bool?) ?? false,
        isActive: (json['is_active'] as bool?) ?? true,
        lastContactedAt: json['last_contacted_at'] != null
            ? DateTime.parse(json['last_contacted_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
