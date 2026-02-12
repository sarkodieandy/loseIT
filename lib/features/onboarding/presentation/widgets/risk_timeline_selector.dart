import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/utils/haptics.dart';

class RiskTimelineSelector extends StatefulWidget {
  const RiskTimelineSelector({
    super.key,
    required this.selectedSlots,
    required this.onChanged,
    this.height = 122,
  });

  final Set<int> selectedSlots;
  final ValueChanged<Set<int>> onChanged;
  final double height;

  @override
  State<RiskTimelineSelector> createState() => _RiskTimelineSelectorState();
}

class _RiskTimelineSelectorState extends State<RiskTimelineSelector> {
  int? _lastSlot;

  void _toggleAt(Offset localPosition, double width) {
    final slot = ((localPosition.dx / width) * 48).floor().clamp(0, 47);
    if (_lastSlot == slot) return;
    _lastSlot = slot;

    final next = {...widget.selectedSlots};
    if (next.contains(slot)) {
      next.remove(slot);
    } else {
      next.add(slot);
    }
    Haptics.selection();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (d) => _toggleAt(d.localPosition, constraints.maxWidth),
          onPanUpdate: (d) => _toggleAt(d.localPosition, constraints.maxWidth),
          onPanEnd: (_) => _lastSlot = null,
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: CustomPaint(
              painter:
                  _RiskTimelinePainter(selectedSlots: widget.selectedSlots),
            ),
          ),
        );
      },
    );
  }
}

class _RiskTimelinePainter extends CustomPainter {
  _RiskTimelinePainter({required this.selectedSlots});

  final Set<int> selectedSlots;

  double _amp(int slot) {
    final t = (slot / 48.0) * math.pi * 2;
    final wave =
        0.55 + 0.32 * math.sin(t * 1.6 - 0.7) + 0.14 * math.sin(t * 3.8 + 1.2);
    return wave.clamp(0.12, 0.95);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / 48;
    final bottom = size.height - 10;

    final axisPaint = Paint()
      ..color = DisciplineColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, bottom), Offset(size.width, bottom), axisPaint);

    for (var i = 0; i < 48; i++) {
      final selected = selectedSlots.contains(i);
      final height = (bottom - 10) * _amp(i);
      final left = i * barWidth + 1.5;
      final right = left + barWidth - 3.0;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, bottom - height, right, bottom),
        const Radius.circular(5),
      );

      final paint = Paint()
        ..color = selected
            ? DisciplineColors.accent
            : DisciplineColors.surface2.withValues(alpha: 0.95);

      if (selected) {
        final glowPaint = Paint()
          ..color = DisciplineColors.accentGlow.withValues(alpha: 0.75)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawRRect(rect, glowPaint);
      }

      canvas.drawRRect(rect, paint);
    }

    // Subtle curve hint.
    final linePath = Path();
    for (var i = 0; i < 48; i++) {
      final x = (i + 0.5) * barWidth;
      final y = bottom - ((bottom - 10) * _amp(i)) - 8;
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = DisciplineColors.textSecondary.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RiskTimelinePainter oldDelegate) {
    return oldDelegate.selectedSlots.length != selectedSlots.length ||
        !oldDelegate.selectedSlots.containsAll(selectedSlots);
  }
}
