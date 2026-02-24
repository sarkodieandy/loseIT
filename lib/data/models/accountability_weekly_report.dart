class AccountabilityWeeklyReport {
  const AccountabilityWeeklyReport({
    required this.id,
    required this.userId,
    this.partnerId,
    required this.weekStartDate,
    required this.journalEntriesCount,
    required this.communityPostsCount,
    required this.daysSober,
    required this.streakMaintained,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? partnerId;
  final DateTime weekStartDate;
  final int journalEntriesCount;
  final int communityPostsCount;
  final int daysSober;
  final bool streakMaintained;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'partner_id': partnerId,
        'week_start_date': weekStartDate.toIso8601String(),
        'journal_entries_count': journalEntriesCount,
        'community_posts_count': communityPostsCount,
        'days_sober': daysSober,
        'streak_maintained': streakMaintained,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory AccountabilityWeeklyReport.fromJson(Map<String, dynamic> json) =>
      AccountabilityWeeklyReport(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        partnerId:
            json['partner_id'] != null ? json['partner_id'].toString() : null,
        weekStartDate: DateTime.parse(json['week_start_date'] as String),
        journalEntriesCount: json['journal_entries_count'] as int? ?? 0,
        communityPostsCount: json['community_posts_count'] as int? ?? 0,
        daysSober: json['days_sober'] as int? ?? 0,
        streakMaintained: json['streak_maintained'] as bool? ?? true,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
