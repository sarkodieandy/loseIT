import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/community/presentation/community_thread_screen.dart';
import '../features/community/presentation/create_group_screen.dart';
import '../features/community/presentation/create_post_screen.dart';
import '../features/community/presentation/daily_checkin_screen.dart';
import '../features/community/presentation/group_detail_screen.dart';
import '../features/community/presentation/group_chat_screen.dart';
import '../features/community/presentation/group_members_screen.dart';
import '../features/challenges/presentation/challenges_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dm/presentation/dm_chat_screen.dart';
import '../features/dm/presentation/dm_inbox_screen.dart';
import '../features/emergency/presentation/emergency_sos_screen.dart';
import '../features/emergency/presentation/recovery_plan_screen.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/support/presentation/support_chat_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/focus/presentation/focus_screen.dart';
import '../features/focus/presentation/urge_timer_screen.dart';
import '../features/milestones/presentation/milestones_screen.dart';
import '../features/journal/presentation/journal_editor_screen.dart';
import '../features/journal/presentation/journal_entry_screen.dart';
import '../features/journal/presentation/journal_screen.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/relapse/presentation/relapse_screen.dart';
import '../features/premium/presentation/paywall_screen.dart';
import '../providers/app_providers.dart';
import '../core/utils/app_logger.dart';
import '../providers/data_providers.dart';
import 'main_shell.dart';

// public navigator key used by other services (notifications, deep links, etc.)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(onboardingCompleteProvider);
  final profileAsync = ref.watch(profileControllerProvider);
  final hasProfile = profileAsync.maybeWhen(
    data: (profile) => profile != null,
    orElse: () => true,
  );
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final onOnboarding = state.matchedLocation == '/onboarding';
      AppLogger.info(
          'router.redirect session=${session?.user.id ?? 'none'}, onOnboarding=$onOnboarding, onboardingComplete=$onboardingComplete, hasProfile=$hasProfile');

      if (session == null || !onboardingComplete) {
        return onOnboarding ? null : '/onboarding';
      }

      if (!hasProfile) {
        return onOnboarding ? null : '/onboarding';
      }

      if (onOnboarding) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingFlow(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/paywall',
        pageBuilder: (context, state) => MaterialPage<void>(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const PaywallScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/journal',
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/community',
                builder: (context, state) => const CommunityScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/journal/new',
        builder: (context, state) => const JournalEditorScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/journal/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JournalEntryScreen(entryId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/new',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/daily-checkin',
        builder: (context, state) => const DailyCheckinScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/groups/new',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/groups/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/groups/:id/chat',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GroupChatScreen(groupId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/groups/:id/members',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return GroupMembersScreen(groupId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/community/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CommunityThreadScreen(postId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/relapse',
        builder: (context, state) => const RelapseScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/dm',
        builder: (context, state) => const DmInboxScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/dm/thread/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final extra = state.extra;
          return DmChatScreen(
            threadId: id,
            otherAlias: extra is String ? extra : null,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/dm/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'];
          final extra = state.extra;
          return DmChatScreen(
            otherUserId: userId,
            otherAlias: extra is String ? extra : null,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/habits',
        builder: (context, state) => const HabitsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/support',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/support/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return SupportChatScreen(connectionId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/focus',
        builder: (context, state) => const FocusScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/focus/urge',
        builder: (context, state) => const UrgeTimerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/emergency-sos',
        builder: (context, state) => const EmergencySosScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/recovery-plan',
        builder: (context, state) => const RecoveryPlanScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/milestones',
        builder: (context, state) {
          // go_router state doesn't always expose queryParameters directly
          final achievementId = state.uri.queryParameters['achievementId'];
          return MilestonesScreen(initialAchievementId: achievementId);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
    ],
  );
});

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
}
