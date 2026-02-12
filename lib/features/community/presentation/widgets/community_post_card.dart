import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../model/community_models.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({super.key, required this.post, this.onTap});

  final CommunityPost post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DisciplineCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                post.alias,
                style: DisciplineTextStyles.section.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: DisciplineColors.surface2,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: DisciplineColors.border.withValues(alpha: 0.75),
                  ),
                ),
                child: Text(
                  '${post.streakDays} day streak',
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.message, style: DisciplineTextStyles.body),
          const SizedBox(height: 12),
          Text(
            '${post.minutesAgo}m ago',
            style: DisciplineTextStyles.caption.copyWith(
              color: DisciplineColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
