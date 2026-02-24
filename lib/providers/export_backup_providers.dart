import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/exported_report.dart';
import '../data/models/cloud_backup.dart';
import '../data/models/backup_schedule.dart';
import './app_providers.dart';

// ========== EXPORTED REPORTS ==========

final exportedReportsProvider =
    FutureProvider.family<List<ExportedReport>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getExportedReports(userId);
});

final createExportedReportProvider =
    FutureProvider.family<bool, ExportedReport>((ref, report) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createExportedReport(report);
  if (result) {
    ref.invalidate(exportedReportsProvider(report.userId));
  }
  return result;
});

// ========== CLOUD BACKUPS ==========

final createCloudBackupProvider =
    FutureProvider.family<bool, CloudBackup>((ref, backup) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.createCloudBackup(backup);
});

// ========== BACKUP SCHEDULES ==========

final backupScheduleProvider =
    FutureProvider.family<BackupSchedule?, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getBackupSchedule(userId);
});

final updateBackupScheduleProvider =
    FutureProvider.family<bool, BackupSchedule>((ref, schedule) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.updateBackupSchedule(schedule);
  if (result) {
    ref.invalidate(backupScheduleProvider(schedule.userId));
  }
  return result;
});

// ========== DATA EXPORT SERVICE (utility functions) ==========

// Helper to generate PDF export filename
String generateExportFilename(String reportType, DateTime date) {
  final dateStr =
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  return '${reportType}_$dateStr.pdf';
}

// Helper to check if backup is needed
final shouldPerformBackupProvider =
    FutureProvider.family<bool, (String, DateTime)>((ref, params) async {
  final userId = params.$1;
  final now = params.$2;

  final schedule = await ref.watch(backupScheduleProvider(userId).future);
  if (schedule == null || !schedule.isEnabled) return false;

  if (schedule.lastBackupAt == null) return true;

  final diff = now.difference(schedule.lastBackupAt!);
  if (schedule.backupFrequency == 'daily') {
    return diff.inHours >= 24;
  } else if (schedule.backupFrequency == 'weekly') {
    return diff.inDays >= 7;
  }

  return false;
});

// ========== AUTO-SYNC STATUS ==========

final dataSyncStatusProvider = StateProvider<
    ({
      bool isBackingUp,
      bool isExporting,
      String? lastSyncTime,
      String? lastError,
    })>((ref) {
  return (
    isBackingUp: false,
    isExporting: false,
    lastSyncTime: null,
    lastError: null,
  );
});
