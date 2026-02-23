class EmergencySession {
  const EmergencySession({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.durationSeconds,
    required this.completed,
    required this.contactedSupport,
    this.notes,
  });

  final String id;
  final DateTime createdAt;
  final String type; // 'breathing', 'grounding', 'support', 'music'
  final int durationSeconds;
  final bool completed;
  final bool contactedSupport;
  final String? notes;

  EmergencySession copyWith({
    String? id,
    DateTime? createdAt,
    String? type,
    int? durationSeconds,
    bool? completed,
    bool? contactedSupport,
    String? notes,
  }) {
    return EmergencySession(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
      contactedSupport: contactedSupport ?? this.contactedSupport,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'EmergencySession(id: $id, type: $type, duration: $durationSeconds, completed: $completed, support: $contactedSupport)';
  }
}
