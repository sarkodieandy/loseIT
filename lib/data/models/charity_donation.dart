class CharityDonation {
  const CharityDonation({
    required this.id,
    required this.userId,
    required this.organizationName,
    this.organizationUrl,
    required this.amountDonated,
    required this.donationDate,
    required this.isRecurring,
    this.recurringFrequency,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String organizationName;
  final String? organizationUrl;
  final double amountDonated;
  final DateTime donationDate;
  final bool isRecurring;
  final String? recurringFrequency; // 'weekly', 'monthly', 'yearly'
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'organization_name': organizationName,
        'organization_url': organizationUrl,
        'amount_donated': amountDonated,
        'donation_date': donationDate.toIso8601String(),
        'is_recurring': isRecurring,
        'recurring_frequency': recurringFrequency,
        'created_at': createdAt.toIso8601String(),
      };

  factory CharityDonation.fromJson(Map<String, dynamic> json) =>
      CharityDonation(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        organizationName: (json['organization_name'] as String?) ?? '',
        organizationUrl: json['organization_url'] as String?,
        amountDonated: (json['amount_donated'] as num?)?.toDouble() ?? 0,
        donationDate: DateTime.parse(json['donation_date'] as String),
        isRecurring: (json['is_recurring'] as bool?) ?? false,
        recurringFrequency: json['recurring_frequency'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
