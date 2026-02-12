import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class LockModeScreen extends StatelessWidget {
  const LockModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final enabled = app.state.onboardingProfile.lockMode;

        return DisciplineScaffold(
          title: 'Lock Mode',
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            children: <Widget>[
              const Text('Stronger protection.',
                  style: DisciplineTextStyles.title),
              const SizedBox(height: 10),
              Text(
                'Lock Mode increases friction during high-risk windows.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 18),
              DisciplineCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Lock Mode',
                            style: DisciplineTextStyles.section),
                        const SizedBox(height: 6),
                        Text(
                          enabled ? 'Enabled' : 'Off',
                          style: DisciplineTextStyles.caption.copyWith(
                            color: enabled
                                ? DisciplineColors.accent
                                : DisciplineColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    CupertinoSwitch(
                      value: enabled,
                      activeTrackColor: DisciplineColors.accent,
                      onChanged: (v) => app.setLockMode(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DisciplineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('What it does',
                        style: DisciplineTextStyles.caption),
                    const SizedBox(height: 12),
                    Text(
                      '• Elevates emergency prompts\n'
                      '• Increases friction during vulnerable windows\n'
                      '• Reinforces decisions with short, focused challenges',
                      style:
                          DisciplineTextStyles.secondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
