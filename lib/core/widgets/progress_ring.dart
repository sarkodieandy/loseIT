import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 160,
    this.strokeWidth = 10,
    this.color = DisciplineColors.accent,
    this.backgroundColor = DisciplineColors.surface2,
    this.child,
    this.animate = true,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;
  final Widget? child;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    Widget ring = CustomPaint(
      painter: _ProgressRingPainter(
        progress: clamped,
        strokeWidth: strokeWidth,
        color: color,
        backgroundColor: backgroundColor,
      ),
      child: SizedBox(width: size, height: size),
    );

    if (animate) {
      ring = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: clamped),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _ProgressRingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              color: color,
              backgroundColor: backgroundColor,
            ),
            child: SizedBox(width: size, height: size),
          );
        },
      );
    }

    if (child == null) return ring;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[ring, child!],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.backgroundColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = backgroundColor.withValues(alpha: 0.9);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color;

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 6
      ..color = color.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius, basePaint);

    final startAngle = -math.pi / 2;
    final sweepAngle = (2 * math.pi) * progress;
    if (sweepAngle > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
