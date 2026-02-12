import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';

class HeatmapCalendar extends StatelessWidget {
  const HeatmapCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.intensityByDay,
  });

  final int year;
  final int month;

  /// 1..31 -> 0..1
  final Map<int, double> intensityByDay;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Sunday = 0
    final startOffset = first.weekday % 7;
    final totalCellsRaw = startOffset + daysInMonth;
    final totalCells = (totalCellsRaw % 7 == 0)
        ? totalCellsRaw
        : totalCellsRaw + (7 - (totalCellsRaw % 7));

    Color cellColor(double intensity) {
      if (intensity <= 0.01) return DisciplineColors.surface2;
      final t = intensity.clamp(0.0, 1.0);
      return Color.lerp(
        DisciplineColors.surface2,
        DisciplineColors.accent.withValues(alpha: 0.9),
        t,
      )!;
    }

    Widget header(String s) {
      return Center(
        child: Text(
          s,
          style: DisciplineTextStyles.caption.copyWith(
            color: DisciplineColors.textTertiary,
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.25,
          children: const <String>['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(header)
              .toList(),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          itemCount: totalCells,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final dayIndex = index - startOffset + 1;
            final inMonth = dayIndex >= 1 && dayIndex <= daysInMonth;
            if (!inMonth) {
              return Container(
                decoration: BoxDecoration(
                  color: DisciplineColors.surface2.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DisciplineColors.border.withValues(alpha: 0.35),
                  ),
                ),
              );
            }

            final intensity = intensityByDay[dayIndex] ?? 0;
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cellColor(intensity),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DisciplineColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                '$dayIndex',
                style: DisciplineTextStyles.caption.copyWith(
                  color: intensity > 0.55
                      ? DisciplineColors.background
                      : DisciplineColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
