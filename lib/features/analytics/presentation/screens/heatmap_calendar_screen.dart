import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../widgets/heatmap_calendar.dart';

class HeatmapCalendarScreen extends StatelessWidget {
  const HeatmapCalendarScreen({super.key});

  Map<int, double> _intensity(int year, int month) {
    final days = DateTime(year, month + 1, 0).day;
    return <int, double>{
      for (var d = 1; d <= days; d++)
        d: (0.15 +
                0.55 *
                    (0.5 + 0.5 * math.sin((d / days) * math.pi * 2.2 - 0.4)) +
                0.12 * (d % 7 == 0 ? 1 : 0))
            .clamp(0.0, 1.0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final intensity = _intensity(now.year, now.month);

    return DisciplineScaffold(
      title: 'Heatmap Calendar',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('Monthly intensity.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Higher intensity indicates stronger discipline performance for that day.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            child: HeatmapCalendar(
              year: now.year,
              month: now.month,
              intensityByDay: intensity,
            ),
          ),
        ],
      ),
    );
  }
}
