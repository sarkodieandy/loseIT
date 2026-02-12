import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';

class PaywallPlanCard extends StatelessWidget {
  const PaywallPlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selected ? DisciplineColors.surface2 : DisciplineColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                (selected ? DisciplineColors.accent : DisciplineColors.border)
                    .withValues(alpha: selected ? 0.95 : 0.7),
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: DisciplineColors.accentGlow.withValues(alpha: 0.65),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        title,
                        style: DisciplineTextStyles.section,
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                DisciplineColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: DisciplineColors.accent
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            badge!,
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: DisciplineTextStyles.caption.copyWith(
                      color: DisciplineColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              price,
              style: DisciplineTextStyles.section.copyWith(
                color: selected
                    ? DisciplineColors.accent
                    : DisciplineColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
