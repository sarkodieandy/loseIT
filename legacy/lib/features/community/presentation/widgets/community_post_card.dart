import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../model/community_models.dart';

class CommunityPostCard extends StatelessWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    this.actionLabel,
    this.onTap,
    this.onAction,
  });

  final CommunityPost post;
  final String? actionLabel;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  String get _initials {
    final parts = post.alias
        .split(RegExp(r'[-_\\s]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  String _timeAgo(int minutesAgo) {
    if (minutesAgo < 1) return 'just now';
    if (minutesAgo < 60) return '$minutesAgo min ago';
    final hours = (minutesAgo / 60).floor();
    if (hours < 24) return '$hours hr ago';
    final days = (hours / 24).floor();
    return '${days}d ago';
  }

  Color _badgeColor() {
    return switch (post.kind) {
      CommunityPostKind.checkIn => DisciplineColors.accent.withValues(alpha: 0.16),
      CommunityPostKind.win => DisciplineColors.success.withValues(alpha: 0.16),
      CommunityPostKind.relapse => DisciplineColors.danger.withValues(alpha: 0.16),
      CommunityPostKind.advice => DisciplineColors.surface2.withValues(alpha: 0.75),
    };
  }

  Color _badgeBorderColor() {
    return switch (post.kind) {
      CommunityPostKind.checkIn => DisciplineColors.accent.withValues(alpha: 0.45),
      CommunityPostKind.win => DisciplineColors.success.withValues(alpha: 0.45),
      CommunityPostKind.relapse => DisciplineColors.danger.withValues(alpha: 0.45),
      CommunityPostKind.advice => DisciplineColors.border.withValues(alpha: 0.7),
    };
  }

  Color _badgeTextColor() {
    return switch (post.kind) {
      CommunityPostKind.checkIn => DisciplineColors.accent,
      CommunityPostKind.win => DisciplineColors.success,
      CommunityPostKind.relapse => DisciplineColors.danger,
      CommunityPostKind.advice => DisciplineColors.textSecondary,
    };
  }

  String _badgeLabel() {
    final explicit = post.label?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    return switch (post.kind) {
      CommunityPostKind.checkIn =>
        post.streakDays > 0 ? 'Day ${post.streakDays} checkpoint' : 'Daily pledge',
      CommunityPostKind.win => 'Milestone',
      CommunityPostKind.relapse =>
        post.streakDays <= 0 ? 'Day 0' : '${post.streakDays} Day Streak',
      CommunityPostKind.advice => 'Advice',
    };
  }

  @override
  Widget build(BuildContext context) {
    final streakLabel =
        post.streakDays <= 0 ? 'Reset' : 'Day ${post.streakDays}';
    final topic = (post.topic == null || post.topic!.trim().isEmpty)
        ? post.kind.label
        : post.topic!.trim();

    return DisciplineCard(
      onTap: onTap,
      shadow: false,
      padding: const EdgeInsets.all(14),
      color: DisciplineColors.surface.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: DisciplineColors.surface2.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DisciplineColors.border.withValues(alpha: 0.75),
                  ),
                ),
                child: Text(
                  _initials,
                  style: DisciplineTextStyles.section.copyWith(
                    fontWeight: FontWeight.w900,
                    color: DisciplineColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${post.alias} • $streakLabel',
                      style: DisciplineTextStyles.section.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$topic • ${_timeAgo(post.minutesAgo)}',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _badgeColor(),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _badgeBorderColor()),
                ),
                child: Text(
                  _badgeLabel(),
                  style: DisciplineTextStyles.caption.copyWith(
                    color: _badgeTextColor(),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.message, style: DisciplineTextStyles.body),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(
                CupertinoIcons.heart,
                size: 16,
                color: DisciplineColors.textSecondary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                post.supportCount.toString(),
                style: DisciplineTextStyles.caption.copyWith(
                  color: DisciplineColors.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                CupertinoIcons.chat_bubble,
                size: 16,
                color: DisciplineColors.textSecondary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                post.commentCount.toString(),
                style: DisciplineTextStyles.caption.copyWith(
                  color: DisciplineColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (actionLabel != null && onAction != null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onAction,
                  child: Text(
                    actionLabel!,
                    style: DisciplineTextStyles.caption.copyWith(
                      color: DisciplineColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
