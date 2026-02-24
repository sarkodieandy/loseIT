import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/accountability_partner.dart';
import '../models/accountability_weekly_report.dart';
import '../models/emergency_sos_contact.dart';
import '../models/craving_log.dart';
import '../models/coping_strategy.dart';
import '../models/recovery_workbook_module.dart';
import '../models/user_workbook_progress.dart';
import '../models/milestone_template.dart';
import '../models/reward_marketplace_item.dart';
import '../models/family_achievement.dart';
import '../models/progress_wall.dart';
import '../models/community_user_badge.dart';
import '../models/notification_preferences.dart';
import '../models/notification_history.dart';
import '../models/focus_session.dart';
import '../models/morning_evening_routine.dart';
import '../models/sobriety_affirmation.dart';
import '../models/financial_goal.dart';
import '../models/spending_log.dart';
import '../models/charity_donation.dart';
import '../models/exported_report.dart';
import '../models/cloud_backup.dart';
import '../models/backup_schedule.dart';
import '../../core/utils/app_logger.dart';

class PremiumFeaturesRepository {
  final SupabaseClient _supabase;

  PremiumFeaturesRepository(this._supabase);

  // ========== ACCOUNTABILITY & SOCIAL FEATURES ==========

  Future<List<AccountabilityPartner>> getAccountabilityPartners(
      String userId) async {
    try {
      final data = await _supabase
          .from('accountability_partners')
          .select()
          .or('user_id.eq.$userId,partner_id.eq.$userId')
          .order('requested_at', ascending: false);
      return (data as List)
          .map((e) => AccountabilityPartner.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('accountability_partners.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> createAccountabilityPartner(
      String userId, String partnerId) async {
    try {
      await _supabase.from('accountability_partners').insert({
        'user_id': userId,
        'partner_id': partnerId,
        'status': 'pending',
      });
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('accountability_partners.create', error, stackTrace);
      return false;
    }
  }

  Future<bool> acceptAccountabilityPartner(String partnerId) async {
    try {
      await _supabase.from('accountability_partners').update({
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String()
      }).eq('id', partnerId);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('accountability_partners.accept', error, stackTrace);
      return false;
    }
  }

  Future<AccountabilityWeeklyReport?> getWeeklyReport(
      String userId, DateTime weekStart) async {
    try {
      final data = await _supabase
          .from('accountability_weekly_reports')
          .select()
          .eq('user_id', userId)
          .eq('week_start_date', weekStart.toIso8601String().split('T')[0])
          .limit(1);
      if (data.isEmpty) return null;
      return AccountabilityWeeklyReport.fromJson(data[0]);
    } catch (error, stackTrace) {
      AppLogger.error('accountability_weekly_reports.get', error, stackTrace);
      return null;
    }
  }

  Future<bool> createWeeklyReport(AccountabilityWeeklyReport report) async {
    try {
      await _supabase
          .from('accountability_weekly_reports')
          .insert(report.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
          'accountability_weekly_reports.create', error, stackTrace);
      return false;
    }
  }

  Future<List<EmergencySosContact>> getEmergencySosContacts(
      String userId) async {
    try {
      final data = await _supabase
          .from('emergency_sos_contacts')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false);
      return (data as List)
          .map((e) => EmergencySosContact.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('emergency_sos_contacts.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> addEmergencySosContact(EmergencySosContact contact) async {
    try {
      await _supabase.from('emergency_sos_contacts').insert(contact.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('emergency_sos_contacts.add', error, stackTrace);
      return false;
    }
  }

  // ========== CRAVING & COPING ==========

  Future<List<CravingLog>> getCravingLogs(String userId,
      {int limit = 50}) async {
    try {
      final data = await _supabase
          .from('craving_logs')
          .select()
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) => CravingLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('craving_logs.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> logCraving(CravingLog craving) async {
    try {
      await _supabase.from('craving_logs').insert(craving.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('craving_logs.log', error, stackTrace);
      return false;
    }
  }

  Future<List<CopingStrategy>> getCopingStrategies(
      {required bool premiumOnly}) async {
    try {
      var query = _supabase.from('coping_strategies').select();
      if (premiumOnly) {
        query = query.eq('is_premium', false);
      }
      final data = await query;
      return (data as List)
          .map((e) => CopingStrategy.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('coping_strategies.get', error, stackTrace);
      return [];
    }
  }

  // ========== RECOVERY WORKBOOK ==========

  Future<List<RecoveryWorkbookModule>> getRecoveryModules(
      {required bool premiumOnly}) async {
    try {
      var query = _supabase.from('recovery_workbook_modules').select();
      if (premiumOnly) {
        query = query.eq('is_premium', false);
      }
      final data = await query.order('order_index', ascending: true);
      return (data as List)
          .map(
              (e) => RecoveryWorkbookModule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('recovery_workbook_modules.get', error, stackTrace);
      return [];
    }
  }

  Future<UserWorkbookProgress?> getModuleProgress(
      String userId, String moduleId) async {
    try {
      final data = await _supabase
          .from('user_workbook_progress')
          .select()
          .eq('user_id', userId)
          .eq('module_id', moduleId)
          .limit(1);
      if (data.isEmpty) return null;
      return UserWorkbookProgress.fromJson(data[0]);
    } catch (error, stackTrace) {
      AppLogger.error('user_workbook_progress.get', error, stackTrace);
      return null;
    }
  }

  Future<bool> completeModule(String userId, String moduleId) async {
    try {
      await _supabase.from('user_workbook_progress').upsert({
        'user_id': userId,
        'module_id': moduleId,
        'completed': true,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,module_id');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('user_workbook_progress.complete', error, stackTrace);
      return false;
    }
  }

  // ========== MILESTONE TEMPLATES & REWARDS ==========

  Future<List<MilestoneTemplate>> getMilestoneTemplates(
      {required bool premiumOnly}) async {
    try {
      var query = _supabase.from('milestone_templates').select();
      if (premiumOnly) {
        query = query.eq('is_premium', false);
      }
      final data = await query.order('days_threshold', ascending: true);
      return (data as List)
          .map((e) => MilestoneTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('milestone_templates.get', error, stackTrace);
      return [];
    }
  }

  Future<List<RewardMarketplaceItem>> getRewardMarketplace() async {
    try {
      final data = await _supabase
          .from('reward_marketplace')
          .select()
          .eq('is_active', true)
          .order('points_required', ascending: true);
      return (data as List)
          .map((e) => RewardMarketplaceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('reward_marketplace.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> redeemReward(
      String userId, String rewardId, int pointsSpent) async {
    try {
      await _supabase.from('user_reward_redemptions').insert({
        'user_id': userId,
        'reward_id': rewardId,
        'points_spent': pointsSpent,
      });
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('user_reward_redemptions.redeem', error, stackTrace);
      return false;
    }
  }

  // ========== FAMILY ACHIEVEMENTS & PROGRESS WALLS ==========

  Future<List<FamilyAchievement>> getFamilyAchievements(String userId) async {
    try {
      final data = await _supabase
          .from('family_achievements')
          .select()
          .eq('user_id', userId)
          .order('celebration_date', ascending: false);
      return (data as List)
          .map((e) => FamilyAchievement.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('family_achievements.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> addFamilyAchievement(FamilyAchievement achievement) async {
    try {
      await _supabase.from('family_achievements').insert(achievement.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('family_achievements.add', error, stackTrace);
      return false;
    }
  }

  Future<ProgressWall?> getProgressWall(String userId) async {
    try {
      final data = await _supabase
          .from('progress_walls')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (data.isEmpty) return null;
      return ProgressWall.fromJson(data[0]);
    } catch (error, stackTrace) {
      AppLogger.error('progress_walls.get', error, stackTrace);
      return null;
    }
  }

  Future<bool> createProgressWall(ProgressWall wall) async {
    try {
      await _supabase.from('progress_walls').insert(wall.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('progress_walls.create', error, stackTrace);
      return false;
    }
  }

  // ========== COMMUNITY BADGES ==========

  Future<List<CommunityUserBadge>> getUserBadges(String userId) async {
    try {
      final data = await _supabase
          .from('community_user_badges')
          .select()
          .eq('user_id', userId);
      return (data as List)
          .map((e) => CommunityUserBadge.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('community_user_badges.get', error, stackTrace);
      return [];
    }
  }

  // ========== NOTIFICATIONS ==========

  Future<NotificationPreferences?> getNotificationPreferences(
      String userId) async {
    try {
      final data = await _supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (data.isEmpty) return null;
      return NotificationPreferences.fromJson(data[0]);
    } catch (error, stackTrace) {
      AppLogger.error('notification_preferences.get', error, stackTrace);
      return null;
    }
  }

  Future<bool> updateNotificationPreferences(
      NotificationPreferences prefs) async {
    try {
      await _supabase
          .from('notification_preferences')
          .upsert(prefs.toJson(), onConflict: 'user_id');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('notification_preferences.update', error, stackTrace);
      return false;
    }
  }

  Future<List<NotificationHistory>> getNotificationHistory(String userId,
      {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('notification_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) => NotificationHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('notification_history.get', error, stackTrace);
      return [];
    }
  }

  // ========== FOCUS SESSIONS & ROUTINES ==========

  Future<List<FocusSession>> getFocusSessions(String userId,
      {int limit = 50}) async {
    try {
      final data = await _supabase
          .from('focus_sessions')
          .select()
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) => FocusSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('focus_sessions.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> createFocusSession(FocusSession session) async {
    try {
      await _supabase.from('focus_sessions').insert(session.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('focus_sessions.create', error, stackTrace);
      return false;
    }
  }

  Future<List<MorningEveningRoutine>> getRoutines(String userId) async {
    try {
      final data = await _supabase
          .from('morning_evening_routines')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);
      return (data as List)
          .map((e) => MorningEveningRoutine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('morning_evening_routines.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> createRoutine(MorningEveningRoutine routine) async {
    try {
      await _supabase.from('morning_evening_routines').insert(routine.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('morning_evening_routines.create', error, stackTrace);
      return false;
    }
  }

  Future<List<SobrietyAffirmation>> getSobrietyAffirmations(
      String userId) async {
    try {
      final data = await _supabase
          .from('sobriety_affirmations')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true);
      return (data as List)
          .map((e) => SobrietyAffirmation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('sobriety_affirmations.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> createAffirmation(SobrietyAffirmation affirmation) async {
    try {
      await _supabase
          .from('sobriety_affirmations')
          .insert(affirmation.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('sobriety_affirmations.create', error, stackTrace);
      return false;
    }
  }

  // ========== FINANCIAL TRACKING ==========

  Future<List<FinancialGoal>> getFinancialGoals(String userId) async {
    try {
      final data = await _supabase
          .from('financial_goals')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => FinancialGoal.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('financial_goals.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> createFinancialGoal(FinancialGoal goal) async {
    try {
      await _supabase.from('financial_goals').insert(goal.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('financial_goals.create', error, stackTrace);
      return false;
    }
  }

  Future<List<SpendingLog>> getSpendingLogs(String userId,
      {int limit = 100}) async {
    try {
      final data = await _supabase
          .from('spending_logs')
          .select()
          .eq('user_id', userId)
          .order('logged_date', ascending: false)
          .limit(limit);
      return (data as List)
          .map((e) => SpendingLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('spending_logs.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> logSpending(SpendingLog log) async {
    try {
      await _supabase.from('spending_logs').insert(log.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('spending_logs.log', error, stackTrace);
      return false;
    }
  }

  Future<List<CharityDonation>> getCharityDonations(String userId) async {
    try {
      final data = await _supabase
          .from('charity_donations')
          .select()
          .eq('user_id', userId)
          .order('donation_date', ascending: false);
      return (data as List)
          .map((e) => CharityDonation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('charity_donations.get', error, stackTrace);
      return [];
    }
  }

  Future<bool> recordCharityDonation(CharityDonation donation) async {
    try {
      await _supabase.from('charity_donations').insert(donation.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('charity_donations.record', error, stackTrace);
      return false;
    }
  }

  // ========== DATA EXPORT & BACKUP ==========

  Future<bool> createExportedReport(ExportedReport report) async {
    try {
      await _supabase.from('exported_reports').insert(report.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('exported_reports.create', error, stackTrace);
      return false;
    }
  }

  Future<List<ExportedReport>> getExportedReports(String userId) async {
    try {
      final data = await _supabase
          .from('exported_reports')
          .select()
          .eq('user_id', userId)
          .eq('is_available', true)
          .order('exported_at', ascending: false);
      return (data as List)
          .map((e) => ExportedReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      AppLogger.error('exported_reports.get', error, stackTrace);
      return [];
    }
  }

  Future<BackupSchedule?> getBackupSchedule(String userId) async {
    try {
      final data = await _supabase
          .from('backup_schedules')
          .select()
          .eq('user_id', userId)
          .limit(1);
      if (data.isEmpty) return null;
      return BackupSchedule.fromJson(data[0]);
    } catch (error, stackTrace) {
      AppLogger.error('backup_schedules.get', error, stackTrace);
      return null;
    }
  }

  Future<bool> updateBackupSchedule(BackupSchedule schedule) async {
    try {
      await _supabase
          .from('backup_schedules')
          .upsert(schedule.toJson(), onConflict: 'user_id');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('backup_schedules.update', error, stackTrace);
      return false;
    }
  }

  Future<bool> createCloudBackup(CloudBackup backup) async {
    try {
      await _supabase.from('cloud_backups').insert(backup.toJson());
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('cloud_backups.create', error, stackTrace);
      return false;
    }
  }
}
