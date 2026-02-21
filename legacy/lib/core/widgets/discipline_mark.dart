import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';
import '../theme/discipline_text_styles.dart';

class DisciplineMark extends StatelessWidget {
  const DisciplineMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = size / 3.15;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DisciplineColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: DisciplineColors.accent.withValues(alpha: 0.55),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DisciplineColors.accentGlow.withValues(alpha: 0.65),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'D',
        style: DisciplineTextStyles.section.copyWith(
          fontSize: size * 0.46,
          fontWeight: FontWeight.w900,
          color: DisciplineColors.accent,
          letterSpacing: -0.8,
        ),
      ),
    );
  }
}
