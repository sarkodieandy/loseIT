# Notification Integration Guide - Implementation Details

## How Notifications Work Now

The app now has a complete Supabase Realtime + Local Notifications system:

### Architecture Flow
```
1. Achievement/Milestone Unlocked
   ↓
2. Call notification provider (e.g., sendAchievementNotificationProvider)
   ↓
3. Log notification to 'notification_history' table in Supabase
   ↓
4. Supabase Realtime detects the insert
   ↓
5. NotificationService listener shows local notification to user
   ↓
6. User sees notification + badge on app
```

---

## Integration Points in Your App

### 1. **When User Reaches a Sobriety Milestone (7, 30, 90 days)**

Example: In achievements/milestones providers or screens

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/notification_providers.dart';

// Inside your milestone checking logic
Future<void> checkAndUnlockMilestones(WidgetRef ref, int daysSober) async {
  if (daysSober == 7) {
    await ref.read(sendMilestoneNotificationProvider(
      MilestoneNotificationParams(
        title: '🎉 7 Days Sober!',
        body: 'You\'ve reached 7 days without relapsing. Keep up the amazing work!',
        milestoneId: 'milestone_7_days',
      ),
    ).future);
  } else if (daysSober == 30) {
    await ref.read(sendMilestoneNotificationProvider(
      MilestoneNotificationParams(
        title: '🚀 30-Day Milestone!',
        body: 'Congratulations! You\'ve been sober for 30 whole days!',
        milestoneId: 'milestone_30_days',
      ),
    ).future);
  } else if (daysSober == 90) {
    await ref.read(sendMilestoneNotificationProvider(
      MilestoneNotificationParams(
        title: '⭐ 90-Day Achievement!',
        body: 'You\'ve reached 90 days sober! You\'re a true champion!',
        milestoneId: 'milestone_90_days',
      ),
    ).future);
  }
}
```

### 2. **When User Unlocks an Achievement**

Example: In achievement unlock logic

```dart
Future<void> unlockAchievement(WidgetRef ref, String achievementId, String title, String description) async {
  // Your unlock logic here...
  
  // Send notification
  await ref.read(sendAchievementNotificationProvider(
    AchievementNotificationParams(
      title: '🏆 Achievement Unlocked: $title',
      body: description,
      achievementId: achievementId,
    ),
  ).future);
}
```

### 3. **Daily App Engagement Reminders**

Already set up! Just enable reminders:

```dart
// In settings/onboarding screen
ElevatedButton(
  onPressed: () async {
    await ref.read(enableDailyRemindersProvider(
      ReminderTimeParams(hour: 8, minute: 0),
    ).future);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily reminders enabled at 8:00 AM')),
    );
  },
  child: const Text('Enable Daily Reminders at 8:00 AM'),
)
```

### 4. **Show Unread Notifications Count**

Display in home screen or app bar:

```dart
Consumer(
  builder: (context, ref, child) {
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
    
    return unreadCountAsync.when(
      data: (count) {
        if (count == 0) return const Icon(Icons.notifications);
        
        return Badge(
          label: Text(count.toString()),
          child: const Icon(Icons.notifications),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, st) => const Icon(Icons.notifications),
    );
  },
)
```

### 5. **Display Notification Center**

Show all unread notifications:

```dart
Consumer(
  builder: (context, ref, child) {
    final notificationsAsync = ref.watch(unreadNotificationsProvider);
    
    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return const Center(child: Text('No new notifications'));
        }
        
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return ListTile(
              title: Text(notif['title'] ?? ''),
              subtitle: Text(notif['body'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.done),
                onPressed: () {
                  ref.read(markAsReadProvider(notif['id']).future);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  },
)
```

### 6. **Quiet Hours (Optional)**

Let users set quiet hours to not be disturbed:

```dart
// In settings
TimePickerButton(
  label: 'Quiet Hours (Do Not Disturb)',
  onTimeSelected: (startTime, endTime) async {
    await ref.read(setQuietHoursProvider(
      QuietHoursParams(
        startTime: startTime, // Format: "22:00"
        endTime: endTime,     // Format: "08:00"
      ),
    ).future);
  },
)
```

---

## Database Tables

Make sure your Supabase has these tables:

### `notification_history` table
```sql
- id (UUID, primary key)
- user_id (UUID, foreign key to auth.users)
- notification_type (text: 'achievement', 'milestone','reminder', 'challenge', etc.)
- title (text)
- body (text)
- related_id (UUID, optional - link to achievement/milestone)
- is_read (boolean, default: false)
- read_at (timestamptz, nullable)
- created_at (timestamptz, default: now())
```

### `notification_preferences` table
```sql
- id (UUID, primary key)
- user_id (UUID, foreign key to auth.users, unique)
- reply_notifications (boolean, default: true)
- message_notifications (boolean, default: true)
- challenge_updates (boolean, default: true)
- milestone_celebrations (boolean, default: true)
- community_digest (boolean, default: true)
- quiet_hours_start (time, nullable) - Format: "HH:MM"
- quiet_hours_end (time, nullable) - Format: "HH:MM"
- created_at (timestamptz, default: now())
- updated_at (timestamptz, default: now())
```

---

## Features Provided

✅ **Achievement Notifications** - High priority, always shows (even during quiet hours)
✅ **Milestone Notifications** - High priority for major achievements
✅ **Daily Reminders** - Scheduled reminders to open app
✅ **Quiet Hours** - Prevent reminders during sleep (set in ISO 8601 format HH:MM)
✅ **Notification Center** - View all notifications in-app
✅ **Unread Count** - Badge showing unread notifications
✅ **Mark as Read** - Mark individual or all notifications as read
✅ **No Firebase** - Uses only Supabase (you already have this!)

---

## Todo: Where to Add Notifications

1. **Dashboard/Home Screen** - When users first open app, check if they earned milestones
2. **Relapse Tracking** - Show encouraging notifications when users log sobriety updates
3. **Challenge Completion** - Notify when challenges are completed
4. **Community Features** - Notify on replies and messages
5. **Premium Milestones** - Special notifications for premium features unlocked

---

## Testing Notifications

To test manually:

```dart
// In your test widget
ElevatedButton(
  onPressed: () {
    ref.read(sendAchievementNotificationProvider(
      AchievementNotificationParams(
        title: '🎉 Test Achievement',
        body: 'This is a test notification',
        achievementId: 'test_achievement',
      ),
    ).future);
  },
  child: const Text('Send Test Notification'),
)
```

---

## Troubleshooting

### Notifications not showing?
1. ✅ Ensure NotificationService initialized in bootstrap
2. ✅ Check Supabase Realtime is enabled
3. ✅ Verify `notification_history` table exists
4. ✅ Check user is authenticated before sending notifications
5. ✅ Check app logs for any errors

### Logs to watch:
```
"NotificationService initialized successfully"
"Supabase Realtime listener started for user: <user_id>"
"Received achievement notification: <title>"
```

---

## Next Steps

1. Integrate `sendAchievementNotificationProvider` in achievement unlock code
2. Integrate `sendMilestoneNotificationProvider` when milestones are reached
3. Add notification center UI to show unread count
4. Set up quiet hours in user settings
