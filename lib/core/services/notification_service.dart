import 'dart:async';

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
import '../utils/anonymous_name.dart';
import '../theme/app_theme.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  static const int _dailyCheckinNotificationId = 9001;
  static const int _defaultDailyCheckinHour = 21; // 9pm local
  static const int _defaultDailyCheckinMinute = 0;

  late FlutterLocalNotificationsPlugin _localNotifications;
  late SupabaseClient _supabase;
  bool _initialized = false;

  StreamSubscription<AuthState>? _authStateSub;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationHistorySub;
  StreamSubscription<List<Map<String, dynamic>>>? _notificationPrefsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _userChallengesSub;
  RealtimeChannel? _groupMessagesChannel;

  String? _activeUserId;
  Set<String> _joinedGroupIds = <String>{};
  final Map<String, String> _groupTitleCache = <String, String>{};
  final Map<String, String> _lastNotifiedMessageIdByGroup = <String, String>{};
  final Map<String, List<Message>> _recentChatMessagesByGroup =
      <String, List<Message>>{};
  bool _messageNotificationsEnabled = true;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static bool _isImageAttachment(String? fileName, String? mimeType) {
    final mime = mimeType?.toLowerCase().trim();
    if (mime != null && mime.startsWith('image/')) return true;
    final name = fileName?.toLowerCase().trim() ?? '';
    if (name.isEmpty || !name.contains('.')) return false;
    final ext = name.split('.').last;
    return <String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}.contains(ext);
  }

  static bool _isVideoAttachment(String? fileName, String? mimeType) {
    final mime = mimeType?.toLowerCase().trim();
    if (mime != null && mime.startsWith('video/')) return true;
    final name = fileName?.toLowerCase().trim() ?? '';
    if (name.isEmpty || !name.contains('.')) return false;
    final ext = name.split('.').last;
    return <String>{'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi'}.contains(ext);
  }

  static String _formatGroupChatNotificationText({
    required String messageType,
    required String content,
    String? attachmentName,
    String? attachmentMime,
  }) {
    final trimmed = content.trim();
    if (messageType != 'file') return trimmed;

    final name = (attachmentName ?? '').trim();
    final safeName = name.isEmpty ? 'Attachment' : name;
    final isImage = _isImageAttachment(safeName, attachmentMime);
    final isVideo = _isVideoAttachment(safeName, attachmentMime);
    final label = isImage ? 'Photo' : isVideo ? 'Video' : 'File';

    if (label == 'File') {
      if (trimmed.isEmpty || trimmed == safeName) {
        return 'File: $safeName';
      }
      return 'File: $safeName — $trimmed';
    }

    if (trimmed.isEmpty || trimmed == safeName) return label;
    return '$label: $trimmed';
  }

  Future<void> dispose() async {
    await _authStateSub?.cancel();
    _authStateSub = null;
    await _stopUserListeners();
    _initialized = false;
  }

  /// Manually refresh group memberships and the group chat notification channel.
  ///
  /// Useful after joining/creating a group if realtime is unavailable.
  Future<void> refreshGroupChatSubscriptions() async {
    final userId = _activeUserId;
    if (userId == null) return;
    try {
      final rows = await _supabase
          .from('user_challenges')
          .select('challenge_id')
          .eq('user_id', userId);

      final normalized = <Map<String, dynamic>>[];
      for (final raw in rows as List) {
        if (raw is Map) {
          normalized.add(Map<String, dynamic>.from(raw));
        }
      }

      await _syncGroupSubscriptions(userId, normalized);
    } catch (e, st) {
      AppLogger.error('notifications.refreshGroups', e, st);
    }
  }

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

      // Request notification permissions (Android 13+)
      final androidImpl =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        if (granted == false) {
          AppLogger.warn('Notifications permission denied on Android');
        }
      }

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

      // Configure local timezone for accurate scheduled notifications.
      await _configureLocalTimezone();

      // Schedule the hourly sober notification (fires on startup)
      scheduleHourlyReminder();

      // Create notification channels (Android)
      await _createNotificationChannels();

      // Keep listeners in sync with the authenticated user.
      _authStateSub = _supabase.auth.onAuthStateChange.listen((state) {
        unawaited(_setActiveUser(state.session?.user.id));
      });

      // Start listeners for the current session (if any)
      await _setActiveUser(_supabase.auth.currentUser?.id);

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

    const AndroidNotificationChannel groupChatChannel =
        AndroidNotificationChannel(
      'group_chat_channel',
      'Group Chat',
      description: 'Notifications for new group chat messages',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(groupChatChannel);
  }

  Future<void> _setActiveUser(String? userId) async {
    if (userId == _activeUserId) return;

    // Stop previous subscriptions (user changed or logged out).
    await _stopUserListeners();

    _activeUserId = userId;
    _recentChatMessagesByGroup.clear();
    if (userId == null) {
      try {
        await _localNotifications.cancel(_dailyCheckinNotificationId);
      } catch (_) {}
      AppLogger.info('Notifications: no active user, listeners stopped');
      return;
    }

    _messageNotificationsEnabled =
        await _loadMessageNotificationsEnabled(userId);
    _listenToNotificationPreferences(userId);

    _listenToSupabaseNotifications(userId);
    _listenToUserGroups(userId);

    // Schedule the daily check-in reminder on app launch and whenever the user logs in.
    unawaited(_syncDailyCheckinReminder(userId));
  }

  Future<void> _stopUserListeners() async {
    await _notificationHistorySub?.cancel();
    _notificationHistorySub = null;

    await _notificationPrefsSub?.cancel();
    _notificationPrefsSub = null;

    await _userChallengesSub?.cancel();
    _userChallengesSub = null;

    _joinedGroupIds = <String>{};
    _groupTitleCache.clear();
    _lastNotifiedMessageIdByGroup.clear();

    final channel = _groupMessagesChannel;
    _groupMessagesChannel = null;
    if (channel != null) {
      try {
        await _supabase.removeChannel(channel);
      } catch (_) {}
    }
  }

  Future<bool> _loadMessageNotificationsEnabled(String userId) async {
    try {
      final row = await _supabase
          .from('notification_preferences')
          .select('message_notifications')
          .eq('user_id', userId)
          .maybeSingle();
      final enabled = row?['message_notifications'];
      if (enabled is bool) return enabled;
      return true;
    } catch (_) {
      return true;
    }
  }

  void _listenToNotificationPreferences(String userId) {
    try {
      _notificationPrefsSub = _supabase
          .from('notification_preferences')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .limit(1)
          .listen(
            (rows) {
              if (rows.isEmpty) return;
              final enabled = rows.first['message_notifications'];
              if (enabled is bool) {
                _messageNotificationsEnabled = enabled;
              }

              final daily = rows.first['community_digest'];
              if (daily is bool) {
                // Keep the daily reminder in sync if user toggles preferences.
                unawaited(_applyDailyCheckinEnabled(userId, daily));
              }
            },
            onError: (_) {},
          );
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await AwesomeNotifications().getLocalTimeZoneIdentifier();
      if (name.trim().isEmpty) return;
      tz.setLocalLocation(tz.getLocation(name));
      AppLogger.info('Timezone configured: $name');
    } catch (e) {
      // Best-effort; fallback to tz.local default.
      AppLogger.warn('Timezone configure failed: $e');
    }
  }

  Future<void> _applyDailyCheckinEnabled(String userId, bool enabled) async {
    if (!enabled) {
      try {
        await _localNotifications.cancel(_dailyCheckinNotificationId);
      } catch (_) {}
      return;
    }
    await _syncDailyCheckinReminder(userId);
  }

  Future<void> _syncDailyCheckinReminder(String userId) async {
    // Use `notification_preferences.community_digest` as the toggle for the daily
    // check-in reminder (keeps DB schema unchanged).
    var enabled = true;
    var shouldUpsertEnabled = false;
    try {
      final row = await _supabase
          .from('notification_preferences')
          .select('community_digest')
          .eq('user_id', userId)
          .maybeSingle();

      if (row == null) {
        enabled = true;
        shouldUpsertEnabled = true;
      } else {
        final raw = row['community_digest'];
        if (raw is bool) {
          enabled = raw;
        } else {
          enabled = true;
          shouldUpsertEnabled = true;
        }
      }
    } catch (e) {
      // If the preferences table isn't available yet, still schedule a reminder.
      enabled = true;
    }

    if (!enabled) {
      try {
        await _localNotifications.cancel(_dailyCheckinNotificationId);
      } catch (_) {}
      return;
    }

    if (shouldUpsertEnabled) {
      try {
        await _supabase.from('notification_preferences').upsert(
          <String, dynamic>{
            'user_id': userId,
            'community_digest': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id',
        );
      } catch (_) {
        // best-effort
      }
    }

    await scheduleDailyReminder(
      id: _dailyCheckinNotificationId,
      hour: _defaultDailyCheckinHour,
      minute: _defaultDailyCheckinMinute,
      title: 'Daily check‑in',
      body: 'Take 30 seconds to check in with your group.',
      payload: 'daily_checkin',
    );
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

  Future<void> showGroupChatNotification({
    required String groupId,
    required String groupTitle,
    required String senderName,
    required String message,
    required String messageId,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    // Respect the user's message notification toggle if available.
    if (!_messageNotificationsEnabled) return;

    // Respect quiet hours if configured.
    if (await _isQuietHours()) return;

    final preview =
        trimmed.length > 180 ? '${trimmed.substring(0, 180)}…' : trimmed;

    final me = Person(
      key: _activeUserId ?? 'me',
      name: 'You',
    );
    final sender = Person(
      key: senderName,
      name: senderName,
    );
    final history = _recentChatMessagesByGroup.putIfAbsent(
      groupId,
      () => <Message>[],
    );
    history.add(Message(preview, DateTime.now(), sender));
    if (history.length > 6) {
      history.removeRange(0, history.length - 6);
    }

    final androidDetails = AndroidNotificationDetails(
      'group_chat_channel',
      'Group Chat',
      channelDescription: 'Notifications for new group chat messages',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      color: AppTheme.seed,
      styleInformation: MessagingStyleInformation(
        me,
        conversationTitle: groupTitle,
        groupConversation: true,
        messages: List<Message>.from(history),
      ),
      enableVibration: true,
      playSound: true,
      showWhen: true,
      groupKey: 'group_chat_$groupId',
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'group_chat_$groupId',
      subtitle: senderName,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use a stable id per group so the notification updates like a real chat.
    final id = groupId.hashCode & 0x7fffffff;
    await _localNotifications.show(
      id,
      groupTitle,
      preview,
      notificationDetails,
      payload: 'group_chat:$groupId',
    );
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
    String payload = 'reminder',
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
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule daily reminder
  Future<void> scheduleDailyReminder({
    int id = 1,
    required int hour,
    required int minute,
    required String title,
    required String body,
    String? payload,
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
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
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
    await Workmanager().cancelByUniqueName('daily_reminder_$userId');
  }

  // Listen to Supabase Realtime for notifications
  void _listenToSupabaseNotifications(String userId) {
    try {
      // Subscribe to realtime stream
      _notificationHistorySub = _supabase
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

  void _listenToUserGroups(String userId) {
    try {
      _userChallengesSub = _supabase
          .from('user_challenges')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen(
            (rows) {
              unawaited(_syncGroupSubscriptions(userId, rows));
            },
            onError: (error) {
              AppLogger.error('user_challenges stream error', error as Object);
            },
          );
    } catch (e) {
      AppLogger.error('_listenToUserGroups', e);
    }
  }

  static bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  Future<void> _syncGroupSubscriptions(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    final groupIds = <String>{};
    for (final row in rows) {
      final groupId = row['challenge_id']?.toString();
      if (groupId == null || groupId.isEmpty) continue;
      groupIds.add(groupId);
    }

    if (_setEquals(_joinedGroupIds, groupIds)) return;
    _joinedGroupIds = groupIds;

    // Clear any cached ids for groups that were left.
    _lastNotifiedMessageIdByGroup
        .removeWhere((groupId, _) => !groupIds.contains(groupId));

    await _warmGroupTitleCache(groupIds);
    await _restartGroupMessagesChannel(userId, groupIds);
  }

  Future<void> _warmGroupTitleCache(Set<String> groupIds) async {
    if (groupIds.isEmpty) return;
    try {
      final missing = groupIds.where((id) => !_groupTitleCache.containsKey(id));
      final ids = missing.toList(growable: false);
      if (ids.isEmpty) return;

      final rows = await _supabase
          .from('challenges')
          .select('id,title')
          .inFilter('id', ids);
      for (final raw in rows as List) {
        final row = Map<String, dynamic>.from(raw as Map);
        final id = row['id']?.toString();
        final title = row['title']?.toString();
        if (id == null || id.isEmpty) continue;
        if (title == null || title.trim().isEmpty) continue;
        _groupTitleCache[id] = title.trim();
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<void> _restartGroupMessagesChannel(
    String userId,
    Set<String> groupIds,
  ) async {
    final existing = _groupMessagesChannel;
    _groupMessagesChannel = null;
    if (existing != null) {
      try {
        await _supabase.removeChannel(existing);
      } catch (_) {}
    }

    if (groupIds.isEmpty) return;

    try {
      final channel = _supabase.channel('group_messages:$userId');
      _groupMessagesChannel = channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'group_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.inFilter,
              column: 'group_id',
              value: groupIds.toList(growable: false),
            ),
            callback: (payload) {
              unawaited(_handleGroupMessageInsert(payload));
            },
          )
          .subscribe();

      AppLogger.info(
          'Group chat notifications enabled for ${groupIds.length} groups');
    } catch (e) {
      AppLogger.error('_restartGroupMessagesChannel', e);
    }
  }

  bool _isViewingGroupChat(String groupId) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return false;
    try {
      final router = GoRouter.of(ctx);
      final path = router.routerDelegate.currentConfiguration.uri.path;
      return path == '/groups/$groupId/chat';
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleGroupMessageInsert(PostgresChangePayload payload) async {
    final userId = _activeUserId;
    if (userId == null) return;

    final record = payload.newRecord;
    final groupId = record['group_id']?.toString();
    if (groupId == null || groupId.isEmpty) return;

    final senderId = record['sender_id']?.toString();
    if (senderId == null || senderId.isEmpty || senderId == userId) return;

    final messageId = record['id']?.toString();
    if (messageId == null || messageId.isEmpty) return;

    // Dedupe for safety.
    if (_lastNotifiedMessageIdByGroup[groupId] == messageId) return;

    // Don't notify if user is already in this chat.
    if (_isViewingGroupChat(groupId)) return;

    final messageType = record['message_type']?.toString() ?? 'text';
    final content = record['content']?.toString() ?? '';
    final attachmentName = record['attachment_name']?.toString();
    final attachmentMime = record['attachment_mime']?.toString();
    final messageText = _formatGroupChatNotificationText(
      messageType: messageType,
      content: content,
      attachmentName: attachmentName,
      attachmentMime: attachmentMime,
    );
    if (messageText.trim().isEmpty) return;

    final groupTitle = _groupTitleCache[groupId] ?? 'Group chat';
    final senderName = anonymousNameFor(senderId);

    try {
      await showGroupChatNotification(
        groupId: groupId,
        groupTitle: groupTitle,
        senderName: senderName,
        message: messageText,
        messageId: messageId,
      );
      _lastNotifiedMessageIdByGroup[groupId] = messageId;
    } catch (e) {
      AppLogger.error('groupChat.notify', e);
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
        } else if (payload == 'daily_checkin') {
          router.push('/daily-checkin');
        } else if (payload == 'paywall') {
          router.push('/paywall');
        } else if (payload.startsWith('group_chat:')) {
          final parts = payload.split(':');
          final groupId = parts.length > 1 ? parts[1] : null;
          if (groupId != null && groupId.isNotEmpty) {
            router.push('/groups/$groupId/chat');
          }
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
        title: 'Daily check‑in',
        body: 'Take 30 seconds to check in with your group.',
        payload: 'daily_checkin',
      );
    }
    return Future.value(true);
  });
}
