import 'package:flutter/cupertino.dart';

import '../../../app/app_controller.dart';
import '../../../core/navigation/discipline_page_route.dart';
import '../../../core/theme/discipline_colors.dart';
import '../../../core/theme/discipline_text_styles.dart';
import '../../../core/widgets/discipline_card.dart';
import '../../../core/widgets/discipline_scaffold.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/risk_indicator.dart';
import '../../emergency/presentation/emergency_flow.dart';
import 'widgets/emergency_urge_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final state = app.state;

        return DisciplineScaffold(
          safeAreaBottom: true,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        state.onboardingProfile.addictionLabel,
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Dashboard',
                          style: DisciplineTextStyles.title),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: DisciplineColors.surface2,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: DisciplineColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          state.isPremium
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.lock,
                          size: 14,
                          color: state.isPremium
                              ? DisciplineColors.accent
                              : DisciplineColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.isPremium ? 'Premium' : 'Standard',
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: ProgressRing(
                  progress: state.streakProgress,
                  size: 176,
                  strokeWidth: 11,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                            begin: 0, end: state.streakDays.toDouble()),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return Text(
                            value.toInt().toString(),
                            style: DisciplineTextStyles.streakNumber,
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'day streak',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              DisciplineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('AI Insight',
                        style: DisciplineTextStyles.caption),
                    const SizedBox(height: 10),
                    Text(
                      'You’ve improved ${state.improvementPercent}% compared to last week.',
                      style: DisciplineTextStyles.section.copyWith(
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay consistent during high-risk windows to protect the streak.',
                      style:
                          DisciplineTextStyles.secondary.copyWith(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DisciplineCard(
                child: RiskIndicator(level: state.riskLevel),
              ),
              const SizedBox(height: 14),
              DisciplineCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Urge Probability',
                              style: DisciplineTextStyles.caption),
                          const SizedBox(height: 10),
                          Text(
                            '${state.urgeProbabilityPercent}%',
                            style: DisciplineTextStyles.title.copyWith(
                              color: DisciplineColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Based on recent patterns.',
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: DisciplineColors.surface2,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              DisciplineColors.border.withValues(alpha: 0.75),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.waveform_path_ecg,
                        color: DisciplineColors.accent.withValues(alpha: 0.95),
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              if ((state.lastReflection ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                DisciplineCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Latest reflection',
                          style: DisciplineTextStyles.caption),
                      const SizedBox(height: 10),
                      Text(
                        state.lastReflection!,
                        style: DisciplineTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              EmergencyUrgeButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.push(
                    DisciplinePageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => EmergencyFlow(
                        showClose: true,
                        onExit: () => navigator.pop(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }
}
