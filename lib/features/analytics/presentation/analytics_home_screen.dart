import 'package:flutter/cupertino.dart';

import '../../../core/navigation/discipline_page_route.dart';
import '../../../core/theme/discipline_text_styles.dart';
import '../../../core/widgets/discipline_card.dart';
import '../../../core/widgets/discipline_scaffold.dart';
import 'screens/emotional_trend_screen.dart';
import 'screens/heatmap_calendar_screen.dart';
import 'screens/risk_time_chart_screen.dart';
import 'screens/streak_timeline_screen.dart';
import 'screens/weekly_summary_screen.dart';

class AnalyticsHomeScreen extends StatelessWidget {
  const AnalyticsHomeScreen({super.key});

  Route<void> _route(Widget page) =>
      DisciplinePageRoute<void>(builder: (_) => page);

  @override
  Widget build(BuildContext context) {
    Widget item({
      required String title,
      required String subtitle,
      required IconData icon,
      required Widget page,
    }) {
      return DisciplineCard(
        onTap: () => Navigator.of(context).push(_route(page)),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF1A1D24),
              ),
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: DisciplineTextStyles.section),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: DisciplineTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_forward, size: 18),
          ],
        ),
      );
    }

    return DisciplineScaffold(
      title: 'Analytics',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('Professional insights.',
              style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Track streak integrity, risk windows, and emotional patterns with minimal noise.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          item(
            title: 'Streak Timeline',
            subtitle: 'Long-term stability view.',
            icon: CupertinoIcons.chart_bar,
            page: const StreakTimelineScreen(),
          ),
          const SizedBox(height: 12),
          item(
            title: 'Heatmap Calendar',
            subtitle: 'Month view intensity.',
            icon: CupertinoIcons.calendar,
            page: const HeatmapCalendarScreen(),
          ),
          const SizedBox(height: 12),
          item(
            title: 'Risk Time Chart',
            subtitle: 'High-risk hours overview.',
            icon: CupertinoIcons.time,
            page: const RiskTimeChartScreen(),
          ),
          const SizedBox(height: 12),
          item(
            title: 'Emotional Trend',
            subtitle: 'Mood correlation curve.',
            icon: CupertinoIcons.heart,
            page: const EmotionalTrendScreen(),
          ),
          const SizedBox(height: 12),
          item(
            title: 'Weekly Summary',
            subtitle: 'Performance delta report.',
            icon: CupertinoIcons.doc_text,
            page: const WeeklySummaryScreen(),
          ),
        ],
      ),
    );
  }
}
