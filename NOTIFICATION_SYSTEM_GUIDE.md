# Notification System Guide (No Firebase)

## Overview
The app now uses a **Supabase Realtime + Local Notifications** system instead of Firebase. This provides:

✅ **Achievement Notifications** - Alert users immediately when they unlock achievements or milestones
✅ **Daily Reminders** - Scheduled reminders throughout the day using Workmanager
✅ **App Engagement** - Encourage users to open the app regularly
✅ **No Firebase** - Uses Supabase Realtime (built-in with your Supabase setup)

---

## Architecture

### Components:
1. **NotificationService** - Local notifications + Supabase Realtime listening
2. **NotificationRepository** - Database operations + logging
3. **notification_providers.dart** - Riverpod providers for app integration
4. **Workmanager** - Background task scheduling for daily reminders

### Flow:
```
Achievement Unlocked 
    ↓
logAchievementNotification() → Supabase notification_history table
    ↓
Supabase Realtime subscription detects insert
    ↓
NotificationService listens and shows local notification
    ↓
User clicks notification → Navigate to achievement screen
```

---

## Setup Instructions

### 1. **Initialize in main.dart**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications
    ref.read(initializeNotificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

### 2. **Android Configuration (AndroidManifest.xml)**

Add these permissions:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 3. **iOS Configuration (Info.plist)**

Add these entries:
```xml
<key>UIUserInterfaceStyle</key>
<string>Light</string>
```

---

## Usage Examples

### **1. Send Achievement Notification**

When user unlocks an achievement:

```dart
// In your achievement unlock handler
ConsumerWidget(
  builder: (context, ref) {
    return ElevatedButton(
      onPressed: () async {
        // Unlock achievement
        await unlockAchievement('achievement_7_days');
        
        // Send notification
        await ref.read(sendAchievementNotificationProvider(
          AchievementNotificationParams(
            title: '🎉 7 Days Sober!',
            body: 'You\'ve reached 7 days without relapsing. Amazing progress!',
            achievementId: 'achievement_7_days',
          ),
        ).future);
      },
      child: const Text('Check Achievement'),
    );
  },
);
```

### **2. Send Milestone Notification**

```dart
await ref.read(sendMilestoneNotificationProvider(
  MilestoneNotificationParams(
    title: '🚀 30-Day Milestone!',
    body: 'Congratulations on reaching 30 days sober!',
    milestoneId: 'milestone_30_days',
  ),
).future);
```

### **3. Enable Daily Reminders**

User enables daily reminders at 8:00 AM:

```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(enableDailyRemindersProvider(
      ReminderTimeParams(hour: 8, minute: 0),
    ).future);
  },
  child: const Text('Enable Daily Reminders at 8:00 AM'),
)
```

### **4. Display Unread Notifications Count**

```dart
Consumer(
  builder: (context, ref, child) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    
    return unreadCount.when(
      data: (count) => Badge(
        backgroundColor: Colors.red,
        label: Text(count.toString()),
        child: const Icon(Icons.notifications),
      ),
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  },
);
```

### **5. Show Notification List**

```dart
Consumer(
  builder: (context, ref, child) {
    final notifications = ref.watch(unreadNotificationsProvider);
    
    return notifications.when(
      data: (notifs) => ListView.builder(
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final notif = notifs[index];
          return ListTile(
            title: Text(notif['title']),
            subtitle: Text(notif['body']),
            trailing: IconButton(
              icon: const Icon(Icons.done),
              onPressed: () {
                ref.read(markAsReadProvider(notif['id']).future);
              },
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(child: Text('Error: $err')),
    );
  },
);
```

### **6. Set Quiet Hours**

Prevent notifications during sleep:

```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(setQuietHoursProvider(
      QuietHoursParams(
        startTime: '22:00', // 10 PM
        endTime: '08:00',   // 8 AM
      ),
    ).future);
  },
  child: const Text('Set Quiet Hours (10 PM - 8 AM)'),
)
```

---

## Notification Types

### **Achievement Notifications**
- Triggered: When user unlocks an achievement
- Sound: ✅ Enabled
- Vibration: ✅ Enabled
- Priority: High

Example:
```
🎉 7 Days Sober!
You've reached 7 days without relapsing. Amazing progress!
```

### **Milestone Notifications**
- Triggered: When user reaches a major milestone (7, 30, 90 days)
- Sound: ✅ Enabled
- Vibration: ✅ Enabled
- Priority: High

Example:
```
🚀 30-Day Milestone!
Congratulations on reaching 30 days sober!
```

### **Daily Reminders**
- Triggered: Scheduled time (e.g., 8 AM)
- Sound: ✅ Enabled
- Vibration: ❌ Disabled (less intrusive)
- Priority: Default

Example:
```
⏰ Time to check your progress!
Open the app to log your daily progress and earn points
```

### **Challenge Notifications**
- Triggered: When challenge is updated
- Sound: ✅ Enabled
- Priority: Default

---

## Advanced Features

### **1. Mark All as Read**

```dart
ElevatedButton(
  onPressed: () {
    ref.read(markAllAsReadProvider);
  },
  child: const Text('Mark All as Read'),
)
```

### **2. Disable Daily Reminders**

```dart
ElevatedButton(
  onPressed: () {
    ref.read(disableDailyRemindersProvider);
  },
  child: const Text('Disable Reminders'),
)
```

### **3. Get Notification Preferences**

```dart
Consumer(
  builder: (context, ref, child) {
    final prefs = ref.watch(notificationPreferencesProvider);
    
    return prefs.when(
      data: (preferences) => Column(
        children: [
          CheckboxListTile(
            title: const Text('Achievement Notifications'),
            value: preferences?['reply_notifications'] ?? true,
            onChanged: (value) {
              // Update preferences
            },
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  },
);
```

---

## Troubleshooting

### **1. Notifications not showing?**

Check:
- ✅ Permissions granted (iOS/Android)
- ✅ NotificationService initialized in main.dart
- ✅ Supabase Realtime enabled
- ✅ Database `notification_history` table exists

### **2. Daily reminders not triggering?**

Check:
- ✅ Workmanager initialized
- ✅ Correct hour/minute parameters
- ✅ Device battery optimization isn't blocking background tasks

### **3. Notifications show old content?**

Clear old notifications:
```dart
final repo = ref.watch(notificationRepositoryProvider);
await repo.deleteOldNotifications(userId);
```

---

## Database Schema

Ensure your Supabase has these tables:

### `notification_history`
```sql
- id (UUID)
- user_id (UUID)
- notification_type (text: 'achievement', 'milestone', 'challenge', etc.)
- title (text)
- body (text)
- related_id (UUID, optional)
- is_read (boolean)
- read_at (timestamptz, optional)
- created_at (timestamptz)
```

### `notification_preferences`
```sql
- id (UUID)
- user_id (UUID, unique)
- reply_notifications (boolean)
- message_notifications (boolean)
- challenge_updates (boolean)
- milestone_celebrations (boolean)
- community_digest (boolean)
- quiet_hours_start (time, optional)
- quiet_hours_end (time, optional)
- created_at (timestamptz)
- updated_at (timestamptz)
```

---

## Summary

✅ **No Firebase required** - Uses Supabase Realtime
✅ **Achievement notifications** - Instant alerts for milestones
✅ **Daily reminders** - Keep users engaged
✅ **Quiet hours** - Prevent notifications during sleep
✅ **Fully customizable** - Easy to extend with new notification types

Happy building! 🚀
