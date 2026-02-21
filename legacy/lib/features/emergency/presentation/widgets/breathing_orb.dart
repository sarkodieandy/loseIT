import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';

class BreathingOrb extends StatelessWidget {
  const BreathingOrb({
    super.key,
    required this.t,
    this.size = 210,
  });

  /// 0..1 (inhale/exhale loop).
  final double t;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = 0.92 + (t * 0.18);
    final glow = 0.22 + (t * 0.14);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              DisciplineColors.accent.withValues(alpha: glow),
              DisciplineColors.accent.withValues(alpha: 0.10),
              DisciplineColors.surface2.withValues(alpha: 0.55),
            ],
            stops: const <double>[0.0, 0.55, 1.0],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: DisciplineColors.accentGlow.withValues(alpha: 0.85),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
      ),
    );
  }
}
