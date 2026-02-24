import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';

class NotificationRepository {
  final SupabaseClient supabase;
  final NotificationService notificationService;

  NotificationRepository(this.supabase, this.notificationService);

  // Log achievement notification (triggers Realtime update)
  Future<void> logAchievementNotification({
    required String userId,
    required String title,
    required String body,
    required String achievementId,
  }) async {
    await supabase.from('notification_history').insert({
      'user_id': userId,
      'notification_type': 'achievement',
      'title': title,
      'body': body,
      'related_id': achievementId,
      'is_read': false,
    });
  }

  // Log milestone notification (triggers Realtime update)
  Future<void> logMilestoneNotification({
    required String userId,
    required String title,
    required String body,
    required String milestoneId,
  }) async {
    await supabase.from('notification_history').insert({
      'user_id': userId,
      'notification_type': 'milestone',
      'title': title,
      'body': body,
      'related_id': milestoneId,
      'is_read': false,
    });
  }

  // Log challenge update notification
  Future<void> logChallengeNotification({
    required String userId,
    required String title,
    required String body,
    required String challengeId,
  }) async {
    await supabase.from('notification_history').insert({
      'user_id': userId,
      'notification_type': 'challenge',
      'title': title,
      'body': body,
      'related_id': challengeId,
      'is_read': false,
    });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await supabase.from('notification_history').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await supabase
        .from('notification_history')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // Get unread notifications count
  Future<int> getUnreadCount(String userId) async {
    final response = await supabase
        .from('notification_history')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  // Get unread notifications
  Future<List<Map<String, dynamic>>> getUnreadNotifications(
      String userId) async {
    final response = await supabase
        .from('notification_history')
        .select()
        .eq('user_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Get all notifications (paginated)
  Future<List<Map<String, dynamic>>> getAllNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await supabase
        .from('notification_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // Get notification preferences
  Future<Map<String, dynamic>?> getNotificationPreferences(
      String userId) async {
    try {
      final response = await supabase
          .from('notification_preferences')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      // Return default preferences if not found
      return {
        'reply_notifications': true,
        'message_notifications': true,
        'challenge_updates': true,
        'milestone_celebrations': true,
        'community_digest': false,
      };
    }
  }

  // Update notification preferences
  Future<void> updateNotificationPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    await supabase.from('notification_preferences').upsert({
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
      ...preferences,
    });
  }

  // Enable daily reminder with specific time
  Future<void> enableDailyReminder({
    required String userId,
    required int hour,
    required int minute,
  }) async {
    // Update preferences
    await supabase.from('notification_preferences').upsert({
      'user_id': userId,
      'community_digest': true,
      'quiet_hours_start': null,
      'quiet_hours_end': null,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Schedule the reminder task
    await notificationService.enableDailyReminderTask(
      userId: userId,
      hour: hour,
      minute: minute,
    );
  }

  // Disable daily reminder
  Future<void> disableDailyReminder(String userId) async {
    // Update preferences
    await supabase
        .from('notification_preferences')
        .update({'community_digest': false}).eq('user_id', userId);

    // Cancel the scheduled task
    await notificationService.disableDailyReminderTask(userId);
  }

  // Set quiet hours (no notifications during this time)
  Future<void> setQuietHours({
    required String userId,
    required String startTime, // Format: "HH:MM"
    required String endTime, // Format: "HH:MM"
  }) async {
    await supabase.from('notification_preferences').update({
      'quiet_hours_start': startTime,
      'quiet_hours_end': endTime,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // Clear quiet hours
  Future<void> clearQuietHours(String userId) async {
    await supabase.from('notification_preferences').update({
      'quiet_hours_start': null,
      'quiet_hours_end': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  // Delete old notifications (older than 30 days)
  Future<void> deleteOldNotifications(String userId) async {
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    await supabase
        .from('notification_history')
        .delete()
        .eq('user_id', userId)
        .lt('created_at', thirtyDaysAgo);
  }
}
