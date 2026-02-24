import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  late FlutterLocalNotificationsPlugin _localNotifications;
  late SupabaseClient _supabase;
  bool _initialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize(SupabaseClient supabaseClient) async {
    if (_initialized) {
      AppLogger.info('NotificationService already initialized');
      return;
    }

    _supabase = supabaseClient;
    AppLogger.info('Initializing NotificationService...');

    try {
      // Initialize timezone for scheduled notifications
      tz_data.initializeTimeZones();

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      _localNotifications = FlutterLocalNotificationsPlugin();
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Request notification permissions (iOS)
      final iosImpl = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final granted = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (!granted!) {
          AppLogger.warn('Notifications permission denied on iOS');
        }
      }

      // Initialize Workmanager for background tasks
      // `isInDebugMode` parameter is deprecated and no longer needed.
      // Debug handlers should be configured separately if required.
      await Workmanager().initialize(callbackDispatcher);

      // Initialize Awesome Notifications for the hourly sober reminder
      await AwesomeNotifications().initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'sober_channel',
            channelName: 'Sober Reminders',
            channelDescription: 'Hourly sobriety reminders',
            defaultColor: const Color(0xFF26B7FF),
            importance: NotificationImportance.High,
            channelShowBadge: true,
          ),
        ],
      );

      // request permission if needed
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      // Schedule the hourly sober notification (fires on startup)
      scheduleHourlyReminder();

      // Create notification channels (Android)
      await _createNotificationChannels();

      // Listen for Supabase Realtime notifications
      _listenToSupabaseNotifications();

      _initialized = true;
      AppLogger.info(
          'NotificationService initialized successfully (permissions granted)');
    } catch (e) {
      AppLogger.error('NotificationService.initialize', e);
    }
  }

  // Create Android notification channels
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel achievementChannel =
        AndroidNotificationChannel(
      'achievement_channel',
      'Achievements & Milestones',
      description: 'Notifications for achievements and milestones',
      importance: Importance.high,
    );

    const AndroidNotificationChannel reminderChannel =
        AndroidNotificationChannel(
      'daily_reminder_channel',
      'Daily Reminders',
      description: 'Daily reminders to open the app',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel motivationalChannel =
        AndroidNotificationChannel(
      'motivational_channel',
      'Motivational Messages',
      description: 'Motivational and engagement messages',
      importance: Importance.low,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(achievementChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(motivationalChannel);
  }

  // Check if current time is within quiet hours
  Future<bool> _isQuietHours() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('notification_preferences')
          .select('quiet_hours_start, quiet_hours_end')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return false;

      final startTime = response['quiet_hours_start'] as String?;
      final endTime = response['quiet_hours_end'] as String?;

      if (startTime == null || endTime == null) return false;

      final now = DateTime.now();
      final currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Handle case where quiet hours span midnight (e.g., 22:00 - 08:00)
      if (startTime.compareTo(endTime) > 0) {
        return currentTime.compareTo(startTime) >= 0 ||
            currentTime.compareTo(endTime) < 0;
      } else {
        return currentTime.compareTo(startTime) >= 0 &&
            currentTime.compareTo(endTime) < 0;
      }
    } catch (e) {
      AppLogger.error('_isQuietHours', e);
      return false;
    }
  }

  // Show achievement notification
  Future<void> showAchievementNotification({
    required String title,
    required String body,
    required String achievementId,
  }) async {
    // Check quiet hours - always show achievements even during quiet hours
    // But you can modify this if you want to respect quiet hours

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'achievement_channel',
      'Achievements & Milestones',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      achievementId.hashCode,
      title,
      body,
      notificationDetails,
      payload: 'achievement:$achievementId',
    );
  }

  // Show reminder notification
  Future<void> showReminderNotification({
    required String title,
    required String body,
  }) async {
    // Respect quiet hours for reminders
    if (await _isQuietHours()) {
      AppLogger.info('Reminder suppressed due to quiet hours');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: 'reminder',
    );
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      1, // Daily reminder ID
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule an hourly sober reminder using Awesome Notifications.
  Future<void> scheduleHourlyReminder() async {
    try {
      // cancel any existing hourly reminders to prevent duplicates
      const int hourlyReminderId = 1;
      await AwesomeNotifications().cancel(hourlyReminderId);
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: hourlyReminderId,
          channelKey: 'sober_channel',
          title: 'Stay sober! 🌿',
          body: 'Open the app and ride your urge.',
          notificationLayout: NotificationLayout.Default,
        ),
        schedule: NotificationInterval(
          interval: const Duration(hours: 1),
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
          repeats: true,
        ),
      );
      AppLogger.info('Scheduled hourly sober reminder');
    } catch (e, st) {
      AppLogger.error('awesome.scheduleHourly', e, st);
    }
  }

  // Enable/disable daily reminders via Workmanager
  Future<void> enableDailyReminderTask({
    required String userId,
    required int hour,
    required int minute,
  }) async {
    await Workmanager().registerPeriodicTask(
      'daily_reminder_$userId',
      'dailyReminderTask',
      frequency: const Duration(days: 1),
      initialDelay: _calculateInitialDelay(hour, minute),
      inputData: {
        'hour': hour,
        'minute': minute,
        'userId': userId,
      },
    );
  }

  // Disable daily reminder task
  Future<void> disableDailyReminderTask(String userId) async {
    await Workmanager().cancelByTag('daily_reminder_$userId');
  }

  // Listen to Supabase Realtime for notifications
  void _listenToSupabaseNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.warn('Cannot listen to notifications: user not authenticated');
      return;
    }

    try {
      // Subscribe to realtime stream
      _supabase
          .from('notification_history')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (event) {
              _handleRealtimeEvent(event);
            },
            onError: (error) {
              AppLogger.error('Realtime stream error', error as Object);
            },
          );

      AppLogger.info('Supabase Realtime listener started for user: $userId');
    } catch (e) {
      AppLogger.error('_listenToSupabaseNotifications', e);
    }
  }

  void _handleRealtimeEvent(List<Map<String, dynamic>> event) {
    try {
      for (final data in event) {
        final notificationType = data['notification_type'] as String?;
        final title = data['title'] as String?;
        final body = data['body'] as String?;
        final id = data['id'] as String?;

        if (id == null) {
          AppLogger.warn('Notification missing id field');
          continue;
        }

        AppLogger.info('Received $notificationType notification: $title');

        if (notificationType == 'achievement') {
          showAchievementNotification(
            title: title ?? 'Achievement Unlocked! 🎉',
            body: body ?? 'You\'ve earned a new achievement!',
            achievementId: id,
          );
        } else if (notificationType == 'milestone') {
          showAchievementNotification(
            title: title ?? 'Milestone Reached! 🚀',
            body: body ?? 'Congratulations on reaching this milestone!',
            achievementId: id,
          );
        } else if (notificationType == 'reminder' ||
            notificationType == 'challenge') {
          showReminderNotification(
            title: title ?? 'Notification',
            body: body ?? 'You have a new update',
          );
        }
      }
    } catch (e) {
      AppLogger.error('_handleRealtimeEvent', e);
    }
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      AppLogger.info('Notification tapped with payload: $payload');

      // Basic routing for notification taps. we use the global router key
      // from app/router.dart so we don't need a BuildContext here.
      // use the public key from router.dart to avoid needing a BuildContext
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return;
      final router = GoRouter.of(ctx);

      if (payload != null) {
        if (payload.startsWith('achievement:')) {
          // deep‑link into the milestones page; we may extend this later
          // to show a specific achievement once a details route exists
          final parts = payload.split(':');
          final achievementId = parts.length > 1 ? parts[1] : null;
          if (achievementId != null && achievementId.isNotEmpty) {
            router.go(
                '/milestones?achievementId=${Uri.encodeComponent(achievementId)}');
          } else {
            router.go('/milestones');
          }
        } else if (payload == 'reminder') {
          router.go('/');
        } else if (payload == 'paywall') {
          router.push('/paywall');
        } else {
          // unknown payload, open home
          router.go('/');
        }
      } else {
        // no payload, show main screen
        router.go('/');
      }
    } catch (e) {
      AppLogger.error('_handleNotificationTap', e);
    }
  }

  // Calculate initial delay for Workmanager
  Duration _calculateInitialDelay(int hour, int minute) {
    final now = DateTime.now();
    var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    return scheduledTime.difference(now);
  }
}

// Callback dispatcher for Workmanager
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'dailyReminderTask') {
      final notificationService = NotificationService();
      await notificationService.showReminderNotification(
        title: '⏰ Time to check your progress!',
        body: 'Open the app to log your daily progress and earn points',
      );
    }
    return Future.value(true);
  });
}
