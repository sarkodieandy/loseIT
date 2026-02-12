import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.alias,
    required this.streakDays,
  });

  final String alias;
  final int streakDays;

  String get _initials {
    final parts =
        alias.split(RegExp(r'[-_\\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1)
      return parts.first.characters.take(2).toString().toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 54,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DisciplineColors.surface2,
            shape: BoxShape.circle,
            border: Border.all(
              color: DisciplineColors.border.withValues(alpha: 0.75),
            ),
          ),
          child: Text(
            _initials,
            style: DisciplineTextStyles.section.copyWith(
              fontWeight: FontWeight.w800,
              color: DisciplineColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${streakDays}d',
          style: DisciplineTextStyles.caption.copyWith(
            color: DisciplineColors.textTertiary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
