// EXAMPLE: Integrating Notifications in Dashboard
// File: lib/features/dashboard/presentation/dashboard_screen.dart
// This shows how to send notifications when milestones are reached

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/core/utils/app_logger.dart';
import 'lib/providers/notification_providers.dart';

class DashboardNotificationMixin {
  /// Call this when checking user's sobriety days
  /// Automatically sends milestone notifications
  static Future<void> checkAndNotifyMilestones(
    WidgetRef ref,
    int daysSober,
  ) async {
    final milestones = {
      7: {
        'title': '🎉 7 Days Sober!',
        'body':
            'You\'ve gone 7 days without relapsing. That\'s amazing progress!',
        'id': 'milestone_7_days',
      },
      14: {
        'title': '💪 Two Weeks Strong!',
        'body': 'You\'ve been sober for 14 days. Keep pushing forward!',
        'id': 'milestone_14_days',
      },
      30: {
        'title': '🚀 30-Day Milestone!',
        'body': 'One month sober! You\'re crushing your goals!',
        'id': 'milestone_30_days',
      },
      60: {
        'title': '⭐ 60 Days Sober!',
        'body': 'Two months! You\'re an unstoppable force!',
        'id': 'milestone_60_days',
      },
      90: {
        'title': '👑 90 Days - Legend Status!',
        'body': 'Three months sober! You\'ve proven you can do this!',
        'id': 'milestone_90_days',
      },
      180: {
        'title': '💎 Half Year Sober!',
        'body': '6 months! You\'re rewriting your story!',
        'id': 'milestone_180_days',
      },
      365: {
        'title': '🏆 One Year Sober!',
        'body': 'A FULL YEAR! You ARE the change you wanted to see!',
        'id': 'milestone_365_days',
      },
    };

    if (milestones.containsKey(daysSober)) {
      final milestone = milestones[daysSober]!;
      try {
        await ref.read(sendMilestoneNotificationProvider(
          MilestoneNotificationParams(
            title: milestone['title']!,
            body: milestone['body']!,
            milestoneId: milestone['id']!,
          ),
        ).future);
        AppLogger.info('Milestone notification sent for day $daysSober');
      } catch (e) {
        AppLogger.error('Failed to send milestone notification', e);
      }
    }
  }

  /// Call this when an achievement is unlocked
  static Future<void> notifyAchievementUnlocked(
    WidgetRef ref,
    String achievementId,
    String title,
    String description,
  ) async {
    try {
      await ref.read(sendAchievementNotificationProvider(
        AchievementNotificationParams(
          title: title,
          body: description,
          achievementId: achievementId,
        ),
      ).future);
      AppLogger.info('Achievement notification sent: $achievementId');
    } catch (e) {
      AppLogger.error('Failed to send achievement notification', e);
    }
  }

  /// Call this for special challenge completions
  static Future<void> notifyChallengeCompleted(
    WidgetRef ref,
    String challengeId,
    String challengeTitle,
  ) async {
    try {
      await ref.read(sendChallengeNotificationProvider(
        ChallengeNotificationParams(
          title: '🎯 Challenge Complete: $challengeTitle',
          body: 'Great job! You\'ve completed a challenge!',
          challengeId: challengeId,
        ),
      ).future);
      AppLogger.info('Challenge notification sent: $challengeId');
    } catch (e) {
      AppLogger.error('Failed to send challenge notification', e);
    }
  }
}

// EXAMPLE USAGE in your Dashboard Screen or Provider:

final dashboardStateProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  // Your existing dashboard logic
  final daysSober = 7; // This would come from your database

  // Note: Don't call checkAndNotifyMilestones from inside a FutureProvider
  // Instead, call it from a ConsumerWidget or ConsumerStatefulWidget

  return {'daysSober': daysSober};
});

// EXAMPLE: Display unread notification count in app bar
class DashboardAppBar extends ConsumerWidget {
  const DashboardAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return AppBar(
      title: const Text('Dashboard'),
      actions: [
        unreadCount.when(
          data: (count) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => _showNotificationCenter(context, ref),
                ),
                if (count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showNotificationCenter(context, ref),
          ),
        ),
      ],
    );
  }

  void _showNotificationCenter(BuildContext context, WidgetRef ref) {
    // Navigate to notification center or show sheet
    showModalBottomSheet(
      context: context,
      builder: (context) => const NotificationCenter(),
    );
  }
}

// EXAMPLE: Notification Center Widget
class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(unreadNotificationsProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No new notifications'),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(markAllAsReadProvider);
                      Navigator.pop(context);
                    },
                    child: const Text('Mark all as read'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    title: Text((notif['title'] as String?) ?? 'Notification'),
                    subtitle: Text((notif['body'] as String?) ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.done),
                      onPressed: () {
                        ref.read(
                            markAsReadProvider(notif['id'] as String).future);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: $err'),
      ),
    );
  }
}

// EXAMPLE: Enable daily reminders in settings
class ReminderSettings extends ConsumerWidget {
  const ReminderSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return prefsAsync.when(
      data: (prefs) {
        return Column(
          children: [
            SwitchListTile(
              title: const Text('Daily Reminder'),
              subtitle: const Text('Remind me to check my progress'),
              value: (prefs?['community_digest'] as bool?) ?? false,
              onChanged: (value) async {
                if (value) {
                  await ref.read(enableDailyRemindersProvider(
                    ReminderTimeParams(hour: 9, minute: 0),
                  ).future);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Daily reminder enabled at 9:00 AM'),
                      ),
                    );
                  }
                } else {
                  await ref.read(disableDailyRemindersProvider.future);
                }
              },
            ),
            SwitchListTile(
              title: const Text('Quiet Hours'),
              subtitle: const Text('No notifications 10 PM - 8 AM'),
              value: prefs?['quiet_hours_start'] != null,
              onChanged: (value) async {
                if (value) {
                  await ref.read(setQuietHoursProvider(
                    QuietHoursParams(startTime: '22:00', endTime: '08:00'),
                  ).future);
                } else {
                  await ref.read(clearQuietHoursProvider.future);
                }
              },
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
