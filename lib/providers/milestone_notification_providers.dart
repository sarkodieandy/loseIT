import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_preferences.dart';
import '../data/models/notification_history.dart';
import '../data/models/milestone_template.dart';
import '../data/models/reward_marketplace_item.dart';
import '../data/models/family_achievement.dart';
import '../data/models/progress_wall.dart';
import '../data/models/community_user_badge.dart';
import './app_providers.dart';

// ========== NOTIFICATION PREFERENCES ==========

final notificationPreferencesProvider =
    FutureProvider.family<NotificationPreferences?, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getNotificationPreferences(userId);
});

final updateNotificationPreferencesProvider =
    FutureProvider.family<bool, NotificationPreferences>((ref, prefs) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.updateNotificationPreferences(prefs);
  if (result) {
    ref.invalidate(notificationPreferencesProvider(prefs.userId));
  }
  return result;
});

// ========== NOTIFICATION HISTORY ==========

final notificationHistoryProvider =
    FutureProvider.family<List<NotificationHistory>, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getNotificationHistory(userId);
});

// ========== MILESTONE TEMPLATES ==========

final milestoneTemplatesProvider =
    FutureProvider<List<MilestoneTemplate>>((ref) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final status = ref.watch(premiumControllerProvider);
  return repo.getMilestoneTemplates(premiumOnly: !status.hasAccess);
});

// ========== REWARD MARKETPLACE ==========

final rewardMarketplaceProvider =
    FutureProvider<List<RewardMarketplaceItem>>((ref) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getRewardMarketplace();
});

final redeemRewardProvider =
    FutureProvider.family<bool, (String, String, int)>((ref, params) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.redeemReward(params.$1, params.$2, params.$3);
  if (result) {
    ref.invalidate(rewardMarketplaceProvider);
  }
  return result;
});

// ========== FAMILY ACHIEVEMENTS ==========

final familyAchievementsProvider =
    FutureProvider.family<List<FamilyAchievement>, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getFamilyAchievements(userId);
});

final addFamilyAchievementProvider =
    FutureProvider.family<bool, FamilyAchievement>((ref, achievement) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.addFamilyAchievement(achievement);
  if (result) {
    ref.invalidate(familyAchievementsProvider(achievement.userId));
  }
  return result;
});

// ========== PROGRESS WALLS ==========

final progressWallProvider =
    FutureProvider.family<ProgressWall?, String>((ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getProgressWall(userId);
});

final createProgressWallProvider =
    FutureProvider.family<bool, ProgressWall>((ref, wall) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  final result = await repo.createProgressWall(wall);
  if (result) {
    ref.invalidate(progressWallProvider(wall.userId));
  }
  return result;
});

// ========== COMMUNITY USER BADGES ==========

final communityUserBadgesProvider =
    FutureProvider.family<List<CommunityUserBadge>, String>(
        (ref, userId) async {
  final repo = ref.watch(premiumFeaturesRepositoryProvider);
  return repo.getUserBadges(userId);
});
