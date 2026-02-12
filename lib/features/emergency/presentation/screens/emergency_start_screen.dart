import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../emergency_flow.dart';

class EmergencyStartScreen extends StatelessWidget {
  const EmergencyStartScreen({
    super.key,
    this.onExit,
    required this.showClose,
  });

  final VoidCallback? onExit;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final state = app.state;

    return DisciplineScaffold(
      title: 'Emergency',
      trailing: showClose
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onExit,
              child: const Icon(
                CupertinoIcons.xmark,
                color: DisciplineColors.textSecondary,
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 14),
          const Text('Stabilize first.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'This is a focused 90-second intervention to reduce intensity and re-route the next action.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Current risk',
                          style: DisciplineTextStyles.caption),
                      const SizedBox(height: 10),
                      Text(
                        '${state.urgeProbabilityPercent}%',
                        style: DisciplineTextStyles.title.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Urge probability estimate.',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DisciplineColors.surface2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: DisciplineColors.border.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: DisciplineColors.accent.withValues(alpha: 0.95),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Start 90-second reset',
            onPressed: () =>
                Navigator.of(context).pushNamed(EmergencyFlow.breathing),
          ),
          const SizedBox(height: 12),
          if (showClose)
            DisciplineButton(
              label: 'Exit',
              variant: DisciplineButtonVariant.secondary,
              onPressed: onExit,
            ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
