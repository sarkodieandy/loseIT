import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';

class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    this.height = 170,
    this.color = DisciplineColors.accent,
    this.highlighted = const <int>{},
  });

  final List<double> values;
  final double height;
  final Color color;
  final Set<int> highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          values: values,
          color: color,
          highlighted: highlighted,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({
    required this.values,
    required this.color,
    required this.highlighted,
  });

  final List<double> values;
  final Color color;
  final Set<int> highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxBars = values.length;
    final barWidth = size.width / maxBars;
    final bottom = size.height - 8;

    for (var i = 0; i < maxBars; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final h = (size.height - 16) * v;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(i * barWidth + 2, bottom - h, barWidth - 4, h),
        const Radius.circular(6),
      );

      final active = highlighted.contains(i);
      final paint = Paint()
        ..color =
            active ? color : DisciplineColors.surface2.withValues(alpha: 0.95);

      if (active) {
        final glow = Paint()
          ..color = color.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawRRect(rect, glow);
      }

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.values.length != values.length ||
        !oldDelegate.highlighted.containsAll(highlighted) ||
        !highlighted.containsAll(oldDelegate.highlighted);
  }
}
