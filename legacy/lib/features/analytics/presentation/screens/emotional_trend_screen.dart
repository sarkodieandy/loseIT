import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../widgets/line_chart.dart';

class EmotionalTrendScreen extends StatelessWidget {
  const EmotionalTrendScreen({super.key});

  List<double> _values() {
    return List<double>.generate(14, (i) {
      final t = i / 13;
      final wave = 0.56 + 0.16 * math.sin(t * math.pi * 2.2 - 0.5);
      final noise = 0.04 * math.sin(t * math.pi * 9.0 + 1.2);
      return (wave + noise).clamp(0.08, 0.92);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _values();

    return DisciplineScaffold(
      title: 'Emotional Trend',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('Emotion correlation.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Track emotional stability against urges and interventions.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('14 days', style: DisciplineTextStyles.caption),
                const SizedBox(height: 12),
                LineChart(values: data, showGrid: false),
                const SizedBox(height: 12),
                const Text(
                  'Note: This is a UI prototype. Real data comes from check-ins.',
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
