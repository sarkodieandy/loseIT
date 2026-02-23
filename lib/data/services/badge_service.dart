import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../models/badge.dart';

class BadgeService {
  BadgeService._();

  static final BadgeService instance = BadgeService._();

  final StreamController<Badge> _badgeEarnedController =
      StreamController<Badge>.broadcast();

  Stream<Badge> get badgeEarnedStream => _badgeEarnedController.stream;

  /// Check and award badges based on user metrics
  Future<List<Badge>> awardBadges({
    required int daysSober,
    required int totalSessions,
    required int journalEntries,
    required int supportContacts,
    required int communityPosts,
    required int sosUsages,
    required int loginStreak,
    required int journalStreak,
    required List<Badge> currentBadges,
  }) async {
    try {
      final newBadges = <Badge>[];

      // Check milestone badges
      if (daysSober >= 1 && !_hasBadge('first_day', currentBadges)) {
        newBadges.add(_awardBadge('first_day'));
      }
      if (daysSober >= 7 && !_hasBadge('one_week', currentBadges)) {
        newBadges.add(_awardBadge('one_week'));
      }
      if (daysSober >= 30 && !_hasBadge('one_month', currentBadges)) {
        newBadges.add(_awardBadge('one_month'));
      }
      if (daysSober >= 90 && !_hasBadge('three_months', currentBadges)) {
        newBadges.add(_awardBadge('three_months'));
      }
      if (daysSober >= 180 && !_hasBadge('six_months', currentBadges)) {
        newBadges.add(_awardBadge('six_months'));
      }
      if (daysSober >= 365 && !_hasBadge('one_year', currentBadges)) {
        newBadges.add(_awardBadge('one_year'));
      }

      // Check streak badges
      if (loginStreak >= 10 && !_hasBadge('daily_keeper', currentBadges)) {
        newBadges.add(_awardBadge('daily_keeper'));
      }
      if (journalStreak >= 30 &&
          !_hasBadge('consistency_king', currentBadges)) {
        newBadges.add(_awardBadge('consistency_king'));
      }

      // Check challenge badges
      if (totalSessions >= 10 && !_hasBadge('focus_master', currentBadges)) {
        newBadges.add(_awardBadge('focus_master'));
      }
      if (sosUsages >= 5 && !_hasBadge('crisis_survivor', currentBadges)) {
        newBadges.add(_awardBadge('crisis_survivor'));
      }

      // Check social badges
      if (supportContacts >= 3 &&
          !_hasBadge('support_network', currentBadges)) {
        newBadges.add(_awardBadge('support_network'));
      }
      if (communityPosts >= 5 && !_hasBadge('community_voice', currentBadges)) {
        newBadges.add(_awardBadge('community_voice'));
      }

      // Emit new badges
      for (final badge in newBadges) {
        if (!_badgeEarnedController.isClosed) {
          _badgeEarnedController.add(badge);
        }
        AppLogger.info('badge: earned ${badge.name}');

        // Persist to Supabase backend
        try {
          final client = Supabase.instance.client;
          final user = client.auth.currentUser;
          if (user != null) {
            // Find the badge ID in the badges table
            final badgesResult = await client
                .from('badges')
                .select('id')
                .eq('name', badge.name)
                .limit(1);

            if (badgesResult.isNotEmpty) {
              final badgeId = badgesResult[0]['id'];
              await client.from('user_badges').insert({
                'user_id': user.id,
                'badge_id': badgeId,
                'earned_at': DateTime.now().toIso8601String(),
              });
            }
          }
        } catch (e) {
          AppLogger.error('badge: failed to persist badge', e, null);
        }
      }

      return newBadges;
    } catch (error, stackTrace) {
      AppLogger.error('badge.awardBadges', error, stackTrace);
      return <Badge>[];
    }
  }

  /// Helper: check if badge already earned
  bool _hasBadge(String badgeId, List<Badge> currentBadges) {
    return currentBadges.any((b) => b.id == badgeId && b.isEarned);
  }

  /// Helper: award a badge
  Badge _awardBadge(String badgeId) {
    final badge = BadgeLibrary.findBadgeById(badgeId);
    if (badge == null) {
      throw Exception('Badge not found: $badgeId');
    }
    return badge.copyWith(earnedAt: DateTime.now());
  }

  /// Get badges by rarity for display
  List<Badge> getBadgesByRarity(List<Badge> allBadges, String rarity) {
    return allBadges.where((b) => b.rarity == rarity).toList();
  }

  /// Get earned badges count by rarity
  Map<String, int> getEarnedStats(List<Badge> allBadges) {
    return <String, int>{
      'common':
          allBadges.where((b) => b.rarity == 'common' && b.isEarned).length,
      'rare': allBadges.where((b) => b.rarity == 'rare' && b.isEarned).length,
      'epic': allBadges.where((b) => b.rarity == 'epic' && b.isEarned).length,
      'legendary':
          allBadges.where((b) => b.rarity == 'legendary' && b.isEarned).length,
    };
  }

  void dispose() {
    _badgeEarnedController.close();
  }
}
