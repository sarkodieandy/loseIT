import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';

class AddictionCard extends StatelessWidget {
  const AddictionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected ? DisciplineColors.surface2 : DisciplineColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                (selected ? DisciplineColors.accent : DisciplineColors.border)
                    .withValues(alpha: selected ? 0.9 : 0.7),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
            if (selected)
              BoxShadow(
                color: DisciplineColors.accentGlow.withValues(alpha: 0.75),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              size: 22,
              color: selected
                  ? DisciplineColors.accent
                  : DisciplineColors.textSecondary,
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
