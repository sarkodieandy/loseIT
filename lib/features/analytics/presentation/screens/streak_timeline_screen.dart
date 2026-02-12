import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../widgets/line_chart.dart';

class StreakTimelineScreen extends StatelessWidget {
  const StreakTimelineScreen({super.key});

  List<double> _values(int improvement) {
    final base = 0.62 - (improvement / 100) * 0.22;
    return List<double>.generate(30, (i) {
      final t = i / 29;
      final wave = 0.09 * math.sin(t * math.pi * 2.0 * 1.4 - 0.6);
      final pulse = (i % 7 == 0) ? 0.05 : 0.0;
      return (base + wave + pulse).clamp(0.08, 0.92);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final state = app.state;
    final data = _values(state.improvementPercent);

    return DisciplineScaffold(
      title: 'Streak Timeline',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('Streak stability.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'A clean view of consistency over the past month.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('30 days', style: DisciplineTextStyles.caption),
                const SizedBox(height: 12),
                LineChart(values: data),
                const SizedBox(height: 12),
                Text(
                  'Current streak: ${state.streakDays} days',
                  style: DisciplineTextStyles.section,
                ),
                const SizedBox(height: 6),
                Text(
                  'Focus on vulnerable windows to protect the streak.',
                  style: DisciplineTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
