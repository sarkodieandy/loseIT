class CloudBackup {
  const CloudBackup({
    required this.id,
    required this.userId,
    required this.backupType,
    required this.dataSnapshot,
    this.backupSizeBytes,
    this.encryptionKeyHash,
    required this.backedUpAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String backupType; // 'auto', 'manual'
  final Map<String, dynamic> dataSnapshot;
  final int? backupSizeBytes;
  final String? encryptionKeyHash;
  final DateTime backedUpAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'backup_type': backupType,
        'data_snapshot': dataSnapshot,
        'backup_size_bytes': backupSizeBytes,
        'encryption_key_hash': encryptionKeyHash,
        'backed_up_at': backedUpAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory CloudBackup.fromJson(Map<String, dynamic> json) => CloudBackup(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        backupType: (json['backup_type'] as String?) ?? 'auto',
        dataSnapshot: (json['data_snapshot'] as Map<String, dynamic>?) ?? {},
        backupSizeBytes: json['backup_size_bytes'] as int?,
        encryptionKeyHash: json['encryption_key_hash'] as String?,
        backedUpAt: DateTime.parse(json['backed_up_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
