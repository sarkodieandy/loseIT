class AccountabilityPartner {
  const AccountabilityPartner({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String partnerId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'partner_id': partnerId,
        'status': status,
        'requested_at': requestedAt.toIso8601String(),
        'accepted_at': acceptedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory AccountabilityPartner.fromJson(Map<String, dynamic> json) =>
      AccountabilityPartner(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        partnerId: json['partner_id'].toString(),
        status: json['status'] as String? ?? 'pending',
        requestedAt: DateTime.parse(json['requested_at'] as String),
        acceptedAt: json['accepted_at'] != null
            ? DateTime.parse(json['accepted_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
