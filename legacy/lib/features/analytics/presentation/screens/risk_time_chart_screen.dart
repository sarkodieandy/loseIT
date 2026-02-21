import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../widgets/bar_chart.dart';

class RiskTimeChartScreen extends StatelessWidget {
  const RiskTimeChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final slots = app.state.onboardingProfile.highRiskSlots;

    final highlighted = <int>{};
    final values = List<double>.generate(24, (hour) {
      final t = hour / 24.0;
      final wave = 0.28 + 0.18 * math.sin(t * math.pi * 2.0 - 0.9);
      final selected = slots.contains(hour * 2) || slots.contains(hour * 2 + 1);
      if (selected) highlighted.add(hour);
      final bump = selected ? 0.36 : 0.0;
      return (wave + bump).clamp(0.06, 0.98);
    });

    return DisciplineScaffold(
      title: 'Risk Time Chart',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('High-risk hours.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Hours marked as high-risk receive elevated interventions and alerts.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('24 hours', style: DisciplineTextStyles.caption),
                const SizedBox(height: 12),
                BarChart(values: values, highlighted: highlighted),
                const SizedBox(height: 12),
                const Text(
                  'Tip: Adjust windows in onboarding anytime.',
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
