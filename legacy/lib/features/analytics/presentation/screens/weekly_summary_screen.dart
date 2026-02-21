import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class WeeklySummaryScreen extends StatelessWidget {
  const WeeklySummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context).state;

    Widget stat(String label, String value, {Color? color}) {
      return Expanded(
        child: DisciplineCard(
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: DisciplineTextStyles.caption),
              const SizedBox(height: 10),
              Text(
                value,
                style: DisciplineTextStyles.section.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color ?? DisciplineColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DisciplineScaffold(
      title: 'Weekly Summary',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('Performance report.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'A compact view of week-over-week changes.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              stat(
                'Improvement',
                '+${state.improvementPercent}%',
                color: DisciplineColors.accent,
              ),
              const SizedBox(width: 12),
              stat('Streak', '${state.streakDays} days'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              stat(
                'Urge probability',
                '${state.urgeProbabilityPercent}%',
              ),
              const SizedBox(width: 12),
              stat(
                'Risk alerts',
                state.onboardingProfile.riskAlertsEnabled ? 'On' : 'Off',
                color: state.onboardingProfile.riskAlertsEnabled
                    ? DisciplineColors.success
                    : DisciplineColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Summary', style: DisciplineTextStyles.caption),
                const SizedBox(height: 10),
                Text(
                  'Maintain your system during peak-risk windows. Emergency interventions are most effective before escalation.',
                  style: DisciplineTextStyles.body,
                ),
                const SizedBox(height: 10),
                Text(
                  'Next action: Review high-risk hours and enable Lock Mode during vulnerable periods.',
                  style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
