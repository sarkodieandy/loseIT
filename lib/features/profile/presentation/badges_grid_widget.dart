import 'package:flutter/material.dart' hide Badge;

import '../../../core/widgets/section_card.dart';
import '../../../data/models/badge.dart';

class BadgesGrid extends StatelessWidget {
  const BadgesGrid({
    super.key,
    required this.badges,
  });

  final List<Badge> badges;

  @override
  Widget build(BuildContext context) {
    final earnedBadges = badges.where((b) => b.isEarned).toList();
    final stats = _getBadgeStats();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Stats summary
        SectionCard(
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              _StatItem('Common', '${stats['common']}'),
              _StatItem('Rare', '${stats['rare']}'),
              _StatItem('Epic', '${stats['epic']}'),
              _StatItem('Legendary', '${stats['legendary']}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Badges grid
        if (earnedBadges.isEmpty)
          SectionCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    const Text(
                      '🎯',
                      style: TextStyle(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No badges earned yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep going! Badges await.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _BadgeItem(badge: badge);
            },
          ),
      ],
    );
  }

  Map<String, int> _getBadgeStats() {
    return <String, int>{
      'common': badges.where((b) => b.rarity == 'common' && b.isEarned).length,
      'rare': badges.where((b) => b.rarity == 'rare' && b.isEarned).length,
      'epic': badges.where((b) => b.rarity == 'epic' && b.isEarned).length,
      'legendary':
          badges.where((b) => b.rarity == 'legendary' && b.isEarned).length,
    };
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  const _BadgeItem({required this.badge});

  final Badge badge;

  Color _getRarityColor(String rarity) {
    return switch (rarity) {
      'common' => Colors.grey,
      'rare' => Colors.blue,
      'epic' => Colors.purple,
      'legendary' => Colors.orange,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _getRarityColor(badge.rarity);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      badge.icon ?? '🏆',
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    badge.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.description ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color),
                        ),
                        child: Text(
                          badge.rarity,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (badge.isEarned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Text(
                            'Earned',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (badge.criteria != null)
                    Text(
                      'Requirement: ${badge.criteria}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: badge.isEarned
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: badge.isEarned
                ? color
                : Theme.of(context).colorScheme.outlineVariant,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Opacity(
                opacity: badge.isEarned ? 1.0 : 0.4,
                child: Text(
                  badge.icon ?? '🏆',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  badge.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: badge.isEarned
                            ? color
                            : Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
