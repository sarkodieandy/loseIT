import 'package:flutter/cupertino.dart';

import '../models/risk_level.dart';
import '../theme/discipline_colors.dart';
import '../theme/discipline_text_styles.dart';

class RiskIndicator extends StatelessWidget {
  const RiskIndicator({super.key, required this.level});

  final RiskLevel level;

  Color _colorFor(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => DisciplineColors.success,
      RiskLevel.medium => DisciplineColors.warning,
      RiskLevel.high => DisciplineColors.danger,
    };
  }

  String _labelFor(RiskLevel level) {
    return switch (level) {
      RiskLevel.low => 'Low',
      RiskLevel.medium => 'Medium',
      RiskLevel.high => 'High',
    };
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _colorFor(level);

    Widget segment(int index, bool active) {
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : DisciplineColors.surface2,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? <BoxShadow>[
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
        ),
      );
    }

    final activeIndex = switch (level) {
      RiskLevel.low => 0,
      RiskLevel.medium => 1,
      RiskLevel.high => 2,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text('Risk Level', style: DisciplineTextStyles.caption),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _labelFor(level),
                key: ValueKey<RiskLevel>(level),
                style: DisciplineTextStyles.caption.copyWith(
                  color: activeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            segment(0, activeIndex == 0),
            const SizedBox(width: 8),
            segment(1, activeIndex == 1),
            const SizedBox(width: 8),
            segment(2, activeIndex == 2),
          ],
        ),
      ],
    );
  }
}
