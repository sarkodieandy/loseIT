import 'package:flutter/cupertino.dart';

import '../core/theme/discipline_colors.dart';
import '../features/analytics/presentation/analytics_home_screen.dart';
import '../features/community/presentation/community_home_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/emergency/presentation/emergency_flow.dart';
import '../features/profile/presentation/profile_home_screen.dart';

class MainTabs extends StatelessWidget {
  const MainTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: DisciplineColors.accent,
        inactiveColor: DisciplineColors.textSecondary,
        backgroundColor: DisciplineColors.navBarScrim,
        border: null,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.speedometer),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.exclamationmark_triangle),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_3),
            label: 'Tribe',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person_circle),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => const DashboardScreen(),
              1 => const EmergencyFlow(),
              2 => const AnalyticsHomeScreen(),
              3 => const CommunityHomeScreen(),
              _ => const ProfileHomeScreen(),
            };
          },
        );
      },
    );
  }
}
