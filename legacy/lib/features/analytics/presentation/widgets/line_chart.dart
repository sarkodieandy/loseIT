import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';

class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.values,
    this.height = 170,
    this.color = DisciplineColors.accent,
    this.showGrid = true,
  });

  final List<double> values;
  final double height;
  final Color color;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _LineChartPainter(
          values: values,
          color: color,
          showGrid: showGrid,
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.color,
    required this.showGrid,
  });

  final List<double> values;
  final Color color;
  final bool showGrid;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint = Paint()
      ..color = DisciplineColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    if (showGrid) {
      for (var i = 1; i <= 3; i++) {
        final y = (size.height / 4) * i;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    final pts = values.map((v) => v.clamp(0.0, 1.0)).toList();
    final dx = size.width / (pts.length - 1);

    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = i * dx;
      final y = size.height - (pts[i] * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    // Focus dot on last point.
    final lastX = (pts.length - 1) * dx;
    final lastY = size.height - (pts.last * size.height);
    canvas.drawCircle(
      Offset(lastX, lastY),
      5.2,
      Paint()..color = DisciplineColors.surface,
    );
    canvas.drawCircle(
      Offset(lastX, lastY),
      3.6,
      Paint()..color = color,
    );

    // Subtle area fill.
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.14),
          color.withValues(alpha: 0.02),
          const Color(0x00000000),
        ],
        stops: const <double>[0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fill, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.values.length != values.length ||
        !_listEquals(oldDelegate.values, values);
  }

  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.0001) return false;
    }
    return true;
  }
}
