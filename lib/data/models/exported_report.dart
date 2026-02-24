class ExportedReport {
  const ExportedReport({
    required this.id,
    required this.userId,
    required this.reportType,
    required this.fileFormat,
    required this.fileUrl,
    this.fileSizeBytes,
    required this.includeJournals,
    required this.includeAnalytics,
    required this.includeMedicalNotes,
    required this.exportedAt,
    required this.isAvailable,
    this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String
      reportType; // 'therapy_summary', 'progress_report', 'full_export'
  final String fileFormat; // 'pdf', 'json', 'csv'
  final String fileUrl;
  final int? fileSizeBytes;
  final bool includeJournals;
  final bool includeAnalytics;
  final bool includeMedicalNotes;
  final DateTime exportedAt;
  final bool isAvailable;
  final DateTime? expiresAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'report_type': reportType,
        'file_format': fileFormat,
        'file_url': fileUrl,
        'file_size_bytes': fileSizeBytes,
        'include_journals': includeJournals,
        'include_analytics': includeAnalytics,
        'include_medical_notes': includeMedicalNotes,
        'exported_at': exportedAt.toIso8601String(),
        'is_available': isAvailable,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ExportedReport.fromJson(Map<String, dynamic> json) => ExportedReport(
        id: json['id'].toString(),
        userId: json['user_id'].toString(),
        reportType: (json['report_type'] as String?) ?? '',
        fileFormat: (json['file_format'] as String?) ?? 'pdf',
        fileUrl: (json['file_url'] as String?) ?? '',
        fileSizeBytes: json['file_size_bytes'] as int?,
        includeJournals: (json['include_journals'] as bool?) ?? true,
        includeAnalytics: (json['include_analytics'] as bool?) ?? true,
        includeMedicalNotes: (json['include_medical_notes'] as bool?) ?? false,
        exportedAt: DateTime.parse(json['exported_at'] as String),
        isAvailable: (json['is_available'] as bool?) ?? true,
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
