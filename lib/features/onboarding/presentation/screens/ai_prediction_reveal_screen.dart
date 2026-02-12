import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/time_slots.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../onboarding_flow.dart';

class AiPredictionRevealScreen extends StatefulWidget {
  const AiPredictionRevealScreen({super.key});

  @override
  State<AiPredictionRevealScreen> createState() =>
      _AiPredictionRevealScreenState();
}

class _AiPredictionRevealScreenState extends State<AiPredictionRevealScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final predicted =
        longestSlotRange(app.state.onboardingProfile.highRiskSlots) ??
            const SlotRange(startSlot: 46, endSlot: 2);

    return DisciplineScaffold(
      title: 'AI Prediction',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          const Text('Pattern prediction.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Discipline detects your highest-risk window and primes intervention in advance.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 190,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                          painter:
                              _InsightGraphPainter(phase: _controller.value),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            DisciplineColors.surface.withValues(alpha: 0.20),
                            DisciplineColors.surface.withValues(alpha: 0.88),
                          ],
                          stops: const <double>[0.0, 0.86],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Insight',
                            style: DisciplineTextStyles.caption,
                          ),
                          const Spacer(),
                          Text(
                            'You are most vulnerable between',
                            style: DisciplineTextStyles.secondary.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatSlotRange(predicted),
                            style: DisciplineTextStyles.title.copyWith(
                              color: DisciplineColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We will elevate protection during this window.',
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Continue',
            onPressed: () =>
                Navigator.of(context).pushNamed(OnboardingFlow.paywall),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _InsightGraphPainter extends CustomPainter {
  _InsightGraphPainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final points = 36;
    for (var i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * size.width;
      final wave =
          0.48 + 0.12 * math.sin((t * math.pi * 2) + phase * math.pi * 2);
      final fine = 0.05 * math.sin((t * math.pi * 6) - phase * math.pi * 2.4);
      final y = (wave + fine) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = DisciplineColors.accent.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final glow = Paint()
      ..color = DisciplineColors.accentGlow.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InsightGraphPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
