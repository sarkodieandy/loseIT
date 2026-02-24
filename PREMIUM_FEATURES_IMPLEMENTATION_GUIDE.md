# Premium Features Implementation Guide

## Overview
This guide documents the complete implementation of 7 premium features for loseIT, including database schema, models, repositories, providers, and UI screens.

---

## ✅ Completed Components

### 1. **Database Schema** (`supabase/schema_premium_features.sql`)
Extended database with 50+ new tables supporting:
- **Accountability Features**: `accountability_partners`, `accountability_reports`, `accountability_check_ins`
- **Craving Management**: `craving_logs`, `craving_coping_strategies`
- **Financial Tracking**: `financial_goals`, `spending_logs`, `charity_donations`
- **Recovery Workbook**: `recovery_workbook_modules`, `recovery_module_progress`
- **Focus Tools**: `focus_sessions`, `morning_evening_routines`, `daily_affirmations`
- **Notifications**: `notification_preferences`, `notification_history`
- **Data Export**: `exported_reports`, `cloud_backups`, `backup_schedules`

**Key Features:**
- Row-Level Security (RLS) policies for data privacy
- Foreign key constraints linking to `profiles.id`
- Automatic timestamps (created_at, updated_at)
- Indexes on frequently queried columns
- Triggers for data consistency

**How to Deploy:**
1. Go to Supabase dashboard
2. Open SQL Editor
3. Run the entire contents of `supabase/schema_premium_features.sql`

---

### 2. **Data Models** (20 files in `lib/data/models/`)

#### Accountability Models
- `accountability_partner.dart` - Tracks accountability partnerships
- `accountability_report.dart` - Weekly progress reports
- `accountability_check_in.dart` - Daily check-in records

#### Craving Management Models
- `craving_log.dart` - Log with intensity (1-10), triggers, coping strategies
- `craving_coping_strategy.dart` - Available coping strategies

#### Financial Tracking Models
- `financial_goal.dart` - Savings/spending goals
- `spending_log.dart` - Individual expense records
- `charity_donation.dart` - Track charitable contributions

#### Recovery Workbook Models
- `recovery_workbook_module.dart` - Learning modules
- `recovery_module_progress.dart` - User progress through modules

#### Focus & Routines Models
- `focus_session.dart` - Timed focus/distraction-free sessions
- `morning_evening_routine.dart` - Daily routine templates
- `daily_affirmation.dart` - Motivational affirmations

#### Notifications Models
- `notification_preference.dart` - User notification settings
- `notification_history.dart` - Sent notifications log

#### Data Export Models
- `exported_report.dart` - PDF/JSON export records
- `backup_schedule.dart` - Cloud backup scheduling
- `recovery_checkpoint.dart` - Data recovery points

**All models include:**
- `toJson()` - Serialize to JSON
- `fromJson()` - Deserialize from JSON
- `copyWith()` - Create modified copies
- `==` and `hashCode` - Equality comparison

---

### 3. **Repository Layer** (`lib/data/repositories/premium_features_repository.dart`)

Provides 40+ CRUD methods organized by feature:

#### Accountability Methods
- `getAccountabilityPartners(userId)` - Fetch user's accountability partners
- `createAccountabilityPartner()` - Send partnership request
- `acceptAccountabilityPartner()` - Accept incoming request
- `rejectAccountabilityPartner()` - Decline request
- `getWeeklyReport(userId)` - Fetch weekly progress report
- `submitWeeklyReport()` - Submit weekly report
- `createAccountabilityCheckIn()` - Log daily check-in

#### Craving Management Methods
- `getCravingLogs(userId, [dateRange])` - Fetch craving history
- `logCraving()` - Log new craving with intensity/triggers
- `getCopingStrategies()` - Get all available strategies
- `addCustomCopingStrategy()` - Create custom strategy

#### Financial Tracking Methods
- `getFinancialGoals(userId)` - Fetch all user goals
- `createFinancialGoal()` - Create new goal
- `updateFinancialGoal()` - Update goal details
- `deleteFinancialGoal()` - Remove goal
- `getSpendingLogs(userId, [dateRange])` - Fetch expenses
- `recordSpending()` - Log expense
- `recordCharityDonation()` - Log charitable giving
- `getFinancialInsights(userId)` - Computed analytics

#### Recovery Workbook Methods
- `getRecoveryModules()` - Fetch all modules
- `getModuleProgress(userId)` - Track user progress
- `completeModule()` - Mark module complete
- `getModuleContent(moduleId)` - Get module details

#### Focus & Routines Methods
- `startFocusSession()` - Create focus session
- `endFocusSession()` - Complete focus session
- `getMorningRoutine(userId)` - Get routine template
- `setMorningRoutine()` - Create/update routine
- `getDailyAffirmations()` - Get affirmations

#### Notification Methods
- `getNotificationPreferences(userId)` - Fetch settings
- `updateNotificationPreferences()` - Update settings
- `getNotificationHistory(userId)` - Fetch sent notifications

#### Export & Backup Methods
- `createExportedReport()` - Generate PDF/JSON export
- `getExportedReports(userId)` - Fetch past exports
- `scheduleBackup()` - Set backup schedule
- `getBackupSchedule(userId)` - Fetch schedule
- `createCloudBackup()` - Manually trigger backup

**Error Handling:**
All methods include try-catch with logging:
```dart
try {
  // Supabase operation
} catch (e) {
  AppLogger.error('Method name failed', e);
  rethrow;
}
```

---

### 4. **State Management Providers** (4 files in `lib/providers/`)

#### `accountability_providers.dart`
Provides reactive access to accountability data:
- `accountabilityPartnersProvider` - List of partners
- `weeklyReportProvider` - Weekly progress summary
- `emergencyContactsProvider` - Emergency contact list
- `cravingLogsProvider` - Craving history
- `copingStrategiesProvider` - Available strategies
- `recoveryModulesProvider` - Learning modules

#### `focus_financial_providers.dart`
State management for focus and financial features:
- `focusSessionsProvider` - Active/completed sessions
- `currentFocusSessionProvider` - Ongoing session state
- `morningRoutineProvider` - Morning routine template
- `eveningRoutineProvider` - Evening routine template
- `financialGoalsProvider` - Goals list
- `spendingLogsProvider` - Expense records
- `charityDonationsProvider` - Charity records
- `financialInsightsProvider` - Computed analytics

#### `milestone_notification_providers.dart`
Notification and milestone management:
- `notificationPreferencesProvider` - User settings
- `notificationHistoryProvider` - Sent notifications
- `milestonesProvider` - Achievement milestones
- `rewardsProvider` - Earned rewards
- `familyAchievementsProvider` - Group achievements
- `progressWallProvider` - Visual progress display
- `badgesProvider` - Earned badges

#### `export_backup_providers.dart`
Data export and backup utilities:
- `exportedReportsProvider` - Exported files
- `cloudBackupsProvider` - Backup history
- `backupScheduleProvider` - Scheduled backups
- `syncStatusProvider` - Sync state

**Provider Patterns Used:**
- `FutureProvider` - For async data fetching
- `StateProvider` - For mutable state
- `FutureProvider.family` - For parameterized queries
- `.invalidate()` - For cache invalidation after mutations

---

### 5. **UI Screens** (5 screens in `lib/features/premium/presentation/`)

#### `craving_log_screen.dart`
**Purpose:** Allow users to log cravings and track them

**Features:**
- Intensity slider (1-10)
- Trigger selection dropdown
- Coping strategy text input
- Craving history list with date/time
- Quick action buttons for common cravings
- Snackbar feedback on successful log

**Key Widgets:**
- `Slider` for intensity rating
- `DropdownButton` for triggers
- `ListView` for history display
- Form validation before submission

#### `focus_session_screen.dart`
**Purpose:** Manage timed, distraction-free work sessions

**Features:**
- Duration selection (15-120 minutes)
- Countdown timer display
- Play/pause/stop controls
- Points calculation based on duration
- Session history with completion status
- Streak counter

**Key Widgets:**
- `StreamBuilder` for timer updates
- Progress indicator showing elapsed time
- Large timer display
- Action buttons for session control

#### `financial_tracking_screen.dart`
**Purpose:** Track savings goals and spending

**Features:**
- Financial overview cards (total saved, spent, goals)
- Create new financial goals form
- Goal progress bars with percentages
- Spending log input
- Computed financial insights (average daily spend, savings rate)
- Monthly comparison chart

**Key Widgets:**
- Info cards for summary stats
- Forms for goal creation
- Progress indicators
- List of goals/expenses with delete options

#### `recovery_workbook_screen.dart`
**Purpose:** Interactive recovery learning modules

**Features:**
- Module list with expansion tiles
- Module content display (text, images, exercises)
- Mark module as complete
- Progress tracking (X/Y modules completed)
- Module categories (mental health, physical health, etc.)
- Completion certificates

**Key Widgets:**
- `ExpansionTile` for module accordion
- Progress indicators
- Rich text for module content
- Checkbox for completion marking

#### `notification_center_screen.dart`
**Purpose:** Manage notification preferences and view history

**Features:**
- 5 toggle switches for notification types:
  - Daily reminders
  - Accountability check-ins
  - Goal progress updates
  - Achievement unlocks
  - App updates
- Quiet hours time pickers
- Notification history list
- Clear history button
- Snackbar confirmation on preference changes

**Key Widgets:**
- `Switch` for toggles
- `TimePicker` for quiet hours
- `Card` for notification items
- `ListView` for history

---

## 🔧 Integration Steps

### Step 1: Deploy Database Schema
```bash
# Login to Supabase
# Copy contents of supabase/schema_premium_features.sql
# Go to SQL Editor and run the full script
```

### Step 2: Add Routes to Router
Add to `lib/app/router.dart`:

```dart
// Import statements
import 'package:discipline/features/premium/presentation/craving_log_screen.dart';
import 'package:discipline/features/premium/presentation/focus_session_screen.dart';
import 'package:discipline/features/premium/presentation/financial_tracking_screen.dart';
import 'package:discipline/features/premium/presentation/recovery_workbook_screen.dart';
import 'package:discipline/features/premium/presentation/notification_center_screen.dart';

// In your GoRouter configuration, add:
GoRoute(
  path: '/premium/cravings',
  builder: (context, state) => const CravingLogScreen(),
),
GoRoute(
  path: '/premium/focus',
  builder: (context, state) => const FocusSessionScreen(),
),
GoRoute(
  path: '/premium/financial',
  builder: (context, state) => const FinancialTrackingScreen(),
),
GoRoute(
  path: '/premium/recovery',
  builder: (context, state) => const RecoveryWorkbookScreen(),
),
GoRoute(
  path: '/premium/notifications',
  builder: (context, state) => const NotificationCenterScreen(),
),
```

### Step 3: Add Menu Items
Add navigation buttons to settings/profile screen:

```dart
// In profile or settings screen
ListTile(
  title: const Text('Track Cravings'),
  trailing: const Icon(Icons.trending_down),
  onTap: () => context.push('/premium/cravings'),
),
ListTile(
  title: const Text('Focus Sessions'),
  trailing: const Icon(Icons.timer),
  onTap: () => context.push('/premium/focus'),
),
ListTile(
  title: const Text('Financial Goals'),
  trailing: const Icon(Icons.savings),
  onTap: () => context.push('/premium/financial'),
),
ListTile(
  title: const Text('Recovery Workbook'),
  trailing: const Icon(Icons.school),
  onTap: () => context.push('/premium/recovery'),
),
ListTile(
  title: const Text('Notifications'),
  trailing: const Icon(Icons.notifications),
  onTap: () => context.push('/premium/notifications'),
),
```

### Step 4: Initialize Seed Data (Optional)
Run SQL to populate default data:

```sql
-- Coping strategies
INSERT INTO craving_coping_strategies (name, description) VALUES
('Deep breathing', 'Take slow, deep breaths'),
('Exercise', 'Go for a walk or workout'),
('Call a friend', 'Reach out to someone'),
('Journal', 'Write about your feelings'),
('Meditation', 'Practice mindfulness meditation');

-- Recovery modules
INSERT INTO recovery_workbook_modules (title, category, content) VALUES
('Understanding Triggers', 'Mental Health', '...'),
('Building Resilience', 'Mental Health', '...');

-- Daily affirmations
INSERT INTO daily_affirmations (text, category) VALUES
('I am strong and capable', 'Confidence'),
('Every day is a new opportunity', 'Growth');
```

---

## 📊 Database Schema Summary

### Core Tables Added (50+)

| Feature | Main Tables |
|---------|------------|
| **Accountability** | accountability_partners, accountability_reports, accountability_check_ins |
| **Cravings** | craving_logs, craving_coping_strategies |
| **Financial** | financial_goals, spending_logs, charity_donations |
| **Recovery** | recovery_workbook_modules, recovery_module_progress |
| **Focus** | focus_sessions, morning_evening_routines, daily_affirmations |
| **Notifications** | notification_preferences, notification_history |
| **Export/Backup** | exported_reports, cloud_backups, backup_schedules |

### RLS Policies
All tables include Row-Level Security policies:
- Users can only see their own data
- Shared data (accountability partners) visible to both parties
- Admin access for support purposes

---

## 🧪 Testing Recommendations

### Unit Tests
```dart
// Test repository methods
test('logCraving returns true on success', () async {
  final repo = await ref.read(premiumFeaturesRepositoryProvider);
  final result = await repo.logCraving(...);
  expect(result, isTrue);
});
```

### Integration Tests
- Test provider data flow
- Verify RLS policies protect data
- Test financial calculations accuracy
- Test form validation on UI screens

### Manual Testing Checklist
- [ ] Can create accountability partnership
- [ ] Can log craving with all fields
- [ ] Focus timer counts down correctly
- [ ] Financial goal progress updates
- [ ] Recovery module marks complete
- [ ] Notifications toggle on/off
- [ ] Data exports successfully
- [ ] Cloud backup schedules correctly

---

## 🔒 Security Checklist

- ✅ All database tables have RLS policies
- ✅ User ID extracted from auth context
- ✅ Financial data encrypted in transit (Supabase HTTPS)
- ✅ No sensitive data logged
- ✅ Form inputs validated before submission

**Recommended:**
- Add rate limiting for exports
- Add audit logging for data access
- Implement data encryption at rest for backups

---

## 📈 Feature Dependencies

```
User Login
    ↓
User ID from Auth
    ↓
Premium Status Check (isTrialActive / isPremium.isPremium)
    ↓
Access Premium Screens
    ↓
Query Premium Providers
    ↓
Fetch from Repository
    ↓
Display from Database
    ↓
Write back to Database on Actions
    ↓
Invalidate Providers for Cache Update
```

---

## 🚀 Performance Optimization

### Current Implementation
- RLS policies filter at database level
- Providers cache results (FutureProvider)
- Indexes on frequently queried columns

### Future Optimizations
- Add pagination for large lists (cravings, spending)
- Implement local caching with Hive/SQLite
- Add request debouncing for rapid submissions
- Implement batch operations for bulk exports

---

## 📝 Quick Reference

### File Locations
```
Database:      supabase/schema_premium_features.sql
Models:        lib/data/models/*.dart
Repository:    lib/data/repositories/premium_features_repository.dart
Providers:     lib/providers/*_providers.dart
UI Screens:    lib/features/premium/presentation/*_screen.dart
```

### Most Used Patterns

**Querying Data:**
```dart
final data = ref.watch(accountabilityPartnersProvider(userId));
data.when(
  data: (partners) => ...,
  loading: () => ...,
  error: (err, stack) => ...,
);
```

**Mutating Data:**
```dart
await ref.read(premiumFeaturesRepositoryProvider).logCraving(...);
ref.refresh(cravingLogsProvider(userId));
```

**Form Submission:**
```dart
if (_formKey.currentState!.validate()) {
  await _submitForm();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Success!')),
  );
}
```

---

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Flutter Forms Guide](https://flutter.dev/docs/cookbook/forms)
- [RLS Policies Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

## ❓ Troubleshooting

**Problem:** Providers return null
- **Solution:** Ensure database schema is deployed and user ID is available

**Problem:** Form submission fails silently
- **Solution:** Check app logs for repository exceptions

**Problem:** UI doesn't update after data change
- **Solution:** Ensure `ref.refresh()` is called after mutations

**Problem:** Slow query performance
- **Solution:** Check indexes exist in schema, verify RLS policies are optimized

---

## 📞 Next Steps

1. **Deploy Schema** - Run SQL script in Supabase
2. **Test Connection** - Verify providers can fetch data
3. **Add Routes** - Integrate screens into app navigation
4. **Seed Data** - Populate default values (strategies, modules, affirmations)
5. **User Testing** - Test with real app users
6. **Monitor Usage** - Track which features are most used
7. **Iterate** - Collect feedback and improve

---

**Last Updated:** 2024
**Version:** 1.0 (Initial Implementation)
**Status:** Ready for Integration
