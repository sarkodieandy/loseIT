import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';

class ChallengeRow extends StatelessWidget {
  const ChallengeRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? DisciplineColors.surface2 : DisciplineColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                (selected ? DisciplineColors.accent : DisciplineColors.border)
                    .withValues(alpha: selected ? 0.85 : 0.7),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              size: 20,
              color: selected
                  ? DisciplineColors.accent
                  : DisciplineColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: DisciplineTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? DisciplineColors.textPrimary
                      : DisciplineColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
