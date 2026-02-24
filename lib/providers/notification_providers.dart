import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/notification_repository.dart';
import '../core/services/notification_service.dart';

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabase = Supabase.instance.client;
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationRepository(supabase, notificationService);
});

// Current user ID provider
final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final supabase = Supabase.instance.client;
  return supabase.auth.currentUser?.id;
});

// Unread notifications count
final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return 0;

  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getUnreadCount(userId);
});

// Get all unread notifications
final unreadNotificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return [];

  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getUnreadNotifications(userId);
});

// Get paginated notifications
final paginatedNotificationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, page) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return [];

  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getAllNotifications(userId, offset: page * 50);
});

// User notification preferences
final notificationPreferencesProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return null;

  final repo = ref.watch(notificationRepositoryProvider);
  return await repo.getNotificationPreferences(userId);
});

// Initialize notification service and listeners
final initializeNotificationsProvider = FutureProvider<void>((ref) async {
  final supabase = Supabase.instance.client;
  final notificationService = ref.watch(notificationServiceProvider);

  // Initialize the notification service with Supabase client
  await notificationService.initialize(supabase);
});

// Send achievement notification
final sendAchievementNotificationProvider =
    FutureProvider.family<void, AchievementNotificationParams>(
        (ref, params) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);

  // Log to database (triggers Realtime auto-notification)
  await repo.logAchievementNotification(
    userId: userId,
    title: params.title,
    body: params.body,
    achievementId: params.achievementId,
  );

  // Invalidate unread count
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(unreadNotificationsProvider);
});

// Send milestone notification
final sendMilestoneNotificationProvider =
    FutureProvider.family<void, MilestoneNotificationParams>(
        (ref, params) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);

  await repo.logMilestoneNotification(
    userId: userId,
    title: params.title,
    body: params.body,
    milestoneId: params.milestoneId,
  );

  // Invalidate unread count
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(unreadNotificationsProvider);
});

// Send challenge notification
final sendChallengeNotificationProvider =
    FutureProvider.family<void, ChallengeNotificationParams>(
        (ref, params) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);

  await repo.logChallengeNotification(
    userId: userId,
    title: params.title,
    body: params.body,
    challengeId: params.challengeId,
  );

  // Invalidate unread count
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(unreadNotificationsProvider);
});

// Enable daily reminders
final enableDailyRemindersProvider =
    FutureProvider.family<void, ReminderTimeParams>((ref, params) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);

  await repo.enableDailyReminder(
    userId: userId,
    hour: params.hour,
    minute: params.minute,
  );

  // Invalidate preferences
  ref.invalidate(notificationPreferencesProvider);
});

// Disable daily reminders
final disableDailyRemindersProvider = FutureProvider<void>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);
  await repo.disableDailyReminder(userId);

  // Invalidate preferences
  ref.invalidate(notificationPreferencesProvider);
});

// Mark all as read
final markAllAsReadProvider = FutureProvider<void>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);
  await repo.markAllAsRead(userId);

  // Invalidate unread count
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(unreadNotificationsProvider);
});

// Mark single notification as read
final markAsReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final repo = ref.watch(notificationRepositoryProvider);
  await repo.markAsRead(notificationId);

  // Invalidate unread count
  ref.invalidate(unreadNotificationCountProvider);
  ref.invalidate(unreadNotificationsProvider);
});

// Set quiet hours
final setQuietHoursProvider =
    FutureProvider.family<void, QuietHoursParams>((ref, params) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);

  await repo.setQuietHours(
    userId: userId,
    startTime: params.startTime,
    endTime: params.endTime,
  );

  // Invalidate preferences
  ref.invalidate(notificationPreferencesProvider);
});

// Clear quiet hours
final clearQuietHoursProvider = FutureProvider<void>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return;

  final repo = ref.watch(notificationRepositoryProvider);
  await repo.clearQuietHours(userId);

  // Invalidate preferences
  ref.invalidate(notificationPreferencesProvider);
});

// Show achievement notification immediately (without logging)
final showAchievementNotificationImmediatelyProvider =
    FutureProvider.family<void, ImmediateNotificationParams>(
        (ref, params) async {
  final notificationService = ref.watch(notificationServiceProvider);

  await notificationService.showAchievementNotification(
    title: params.title,
    body: params.body,
    achievementId: params.achievementId,
  );
});

// Show reminder notification immediately
final showReminderNotificationImmediatelyProvider =
    FutureProvider.family<void, ReminderNotificationParams>(
        (ref, params) async {
  final notificationService = ref.watch(notificationServiceProvider);

  await notificationService.showReminderNotification(
    title: params.title,
    body: params.body,
  );
});

// Models for notification parameters
class AchievementNotificationParams {
  final String title;
  final String body;
  final String achievementId;

  AchievementNotificationParams({
    required this.title,
    required this.body,
    required this.achievementId,
  });
}

class MilestoneNotificationParams {
  final String title;
  final String body;
  final String milestoneId;

  MilestoneNotificationParams({
    required this.title,
    required this.body,
    required this.milestoneId,
  });
}

class ChallengeNotificationParams {
  final String title;
  final String body;
  final String challengeId;

  ChallengeNotificationParams({
    required this.title,
    required this.body,
    required this.challengeId,
  });
}

class ReminderTimeParams {
  final int hour;
  final int minute;

  ReminderTimeParams({
    required this.hour,
    required this.minute,
  });
}

class QuietHoursParams {
  final String startTime; // Format: "HH:MM"
  final String endTime; // Format: "HH:MM"

  QuietHoursParams({
    required this.startTime,
    required this.endTime,
  });
}

class ImmediateNotificationParams {
  final String title;
  final String body;
  final String achievementId;

  ImmediateNotificationParams({
    required this.title,
    required this.body,
    required this.achievementId,
  });
}

class ReminderNotificationParams {
  final String title;
  final String body;

  ReminderNotificationParams({
    required this.title,
    required this.body,
  });
}
