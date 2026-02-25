class RecoveryPlan {
  const RecoveryPlan({
    required this.userId,
    required this.triggers,
    required this.warningSigns,
    required this.copingActions,
    this.supportMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final List<String> triggers;
  final List<String> warningSigns;
  final List<String> copingActions;
  final String? supportMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static DateTime _readDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.parse(value).toLocal();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toUpsertJson() => <String, dynamic>{
        'user_id': userId,
        'triggers': triggers,
        'warning_signs': warningSigns,
        'coping_actions': copingActions,
        'support_message': supportMessage,
      };

  factory RecoveryPlan.fromJson(Map<String, dynamic> json) {
    return RecoveryPlan(
      userId: (json['user_id'] as String?) ?? '',
      triggers: _readStringList(json['triggers']),
      warningSigns: _readStringList(json['warning_signs']),
      copingActions: _readStringList(json['coping_actions']),
      supportMessage: (json['support_message'] as String?)?.trim().isEmpty == true
          ? null
          : (json['support_message'] as String?),
      createdAt: _readDate(json['created_at']),
      updatedAt: _readDate(json['updated_at']),
    );
  }
}

