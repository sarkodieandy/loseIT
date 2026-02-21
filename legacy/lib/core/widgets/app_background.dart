import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';
import '../theme/discipline_tokens.dart';

class AppBackground extends StatefulWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (DisciplineMotion.reduceMotion(context)) {
      return _frame(0.0);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _frame(_controller.value),
    );
  }

  Widget _frame(double t) {
    final eased = Curves.easeInOut.transform(t);
    final center = Alignment(
      (-0.04 + (0.08 * eased)),
      (-0.92 + (0.05 * (0.5 - (eased - 0.5).abs()) * 2)),
    );
    final accentGlow = DisciplineColors.accent.withValues(
      alpha: 0.16 + (0.06 * eased),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DisciplineColors.background,
        gradient: RadialGradient(
          center: center,
          radius: 1.28,
          colors: <Color>[
            accentGlow,
            DisciplineColors.backgroundTop,
            DisciplineColors.background,
          ],
          stops: const <double>[0.0, 0.38, 1.0],
        ),
      ),
      child: widget.child,
    );
  }
}
