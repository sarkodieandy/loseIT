import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/unread_dot.dart';
import '../../../data/models/group_checkin.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/group_chat_unread_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final groupAsync = ref.watch(groupProvider(groupId));
    final joinedAsync = ref.watch(userChallengesProvider);

    final isJoined = joinedAsync.asData?.value
            .any((item) => item.challengeId == groupId) ??
        false;
    final hasUnread = isJoined
        ? ref.watch(groupChatHasUnreadProvider(groupId))
        : false;

    final groupTitle = groupAsync.asData?.value?.title ?? 'Group';

    return Scaffold(
      backgroundColor: TribeColors.bgTop(context),
      appBar: AppBar(
        title: Text(groupTitle),
        actions: <Widget>[
          if (isJoined)
            TextButton(
              onPressed: () async {
                await ref.read(challengesRepositoryProvider).leaveGroup(groupId);
                ref.invalidate(userChallengesProvider);
                ref.invalidate(challengesProvider);
                if (context.mounted) context.pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Leave'),
            ),
        ],
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return Center(
              child: Text(
                'Group not found.',
                style: TextStyle(color: TribeColors.muted(context)),
              ),
            );
          }

          final memberCount = group.memberCount;
          final schedule = (group.description?.trim().isNotEmpty ?? false)
              ? group.description!.trim()
              : null;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              _Card(
                child: Row(
                  children: <Widget>[
                    _GroupBadge(
                      title: group.title,
                      seed: group.id,
                      imageUrl: group.badgeImageUrl,
                      size: 46,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            group.title,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _MetaPill(
                                icon: Icons.people_outline,
                                label: '$memberCount members',
                              ),
                              if (schedule != null)
                                _MetaPill(
                                  icon: Icons.schedule,
                                  label: schedule,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Card(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => context.push('/groups/$groupId/chat'),
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Icon(
                        Icons.chat_bubble_outline,
                        color: TribeColors.muted(context),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: -1,
                          top: -1,
                          child: UnreadDot(
                            size: 12,
                            borderColor: TribeColors.card(context),
                          ),
                        ),
                    ],
                  ),
                  title: const Text(
                    'Group chat',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Share check-ins and support.',
                    style: TextStyle(color: TribeColors.muted(context)),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: TribeColors.muted(context)),
                ),
              ),
              const SizedBox(height: 12),
              _ChatPreview(groupId: groupId),
              const SizedBox(height: 18),
              if (session == null)
                _Card(
                  child: Text(
                    'Sign in to join and check-in.',
                    style: TextStyle(color: TribeColors.muted(context)),
                  ),
                )
              else if (!isJoined)
                _Card(
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Join this group to start daily check-ins.',
                          style: TextStyle(
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(challengesRepositoryProvider)
                              .startChallenge(groupId);
                          ref.invalidate(userChallengesProvider);
                          ref.invalidate(challengesProvider);
                        },
                        child: const Text('Join'),
                      ),
                    ],
                  ),
                )
              else
                _CheckinPanel(groupId: groupId),
              const SizedBox(height: 18),
              Text(
                'Today',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: TribeColors.muted(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              _TodayCheckins(groupId: groupId),
              const SizedBox(height: 18),
              Text(
                'Streak board',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: TribeColors.muted(context),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              _StreakBoard(groupId: groupId),
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _friendlyError(error),
              style: TextStyle(color: TribeColors.muted(context)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  static String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('relation \"public.group_checkins\"') ||
        message.contains('group_checkins')) {
      return 'Group check-ins backend is not set up yet.\n\n'
          'Run `supabase/schema.sql` in Supabase SQL Editor to create `group_checkins` and policies.';
    }
    return 'Failed: $message';
  }
}

class _ChatPreview extends ConsumerWidget {
  const _ChatPreview({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(groupMessagesProvider(groupId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return _Card(
            child: Text(
              'No messages yet. Start the conversation.',
              style: TextStyle(color: TribeColors.muted(context)),
            ),
          );
        }

        final recent = messages.take(3).toList(growable: false);
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Recent messages',
                style: TextStyle(
                  color: TribeColors.muted(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...recent.map((m) {
                final alias = anonymousNameFor(m.senderId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      _Avatar(seed: m.senderId),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              alias,
                              style: TextStyle(
                                color: TribeColors.textPrimary(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: TribeColors.muted(context)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Formatters.timeAgo(m.createdAt),
                        style: TextStyle(
                          color: TribeColors.muted(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CheckinPanel extends ConsumerStatefulWidget {
  const _CheckinPanel({required this.groupId});

  final String groupId;

  @override
  ConsumerState<_CheckinPanel> createState() => _CheckinPanelState();
}

class _CheckinPanelState extends ConsumerState<_CheckinPanel> {
  bool _saving = false;

  Future<void> _checkIn() async {
    if (_saving) return;
    final noteController = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily check-in'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional note…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(noteController.text.trim()),
            child: const Text('Check in'),
          ),
        ],
      ),
    );

    setState(() => _saving = true);
    try {
      await ref.read(challengesRepositoryProvider).createGroupCheckin(
            groupId: widget.groupId,
            note: (note ?? '').trim().isEmpty ? null : note,
          );
    } catch (error, stackTrace) {
      AppLogger.error('groups.checkin', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final checkinsAsync = ref.watch(groupCheckinsProvider(widget.groupId));

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final checkins = checkinsAsync.asData?.value ?? const <GroupCheckin>[];
    final myId = session?.user.id;
    final checkedInToday = myId == null
        ? false
        : checkins.any((c) {
            final d = DateTime(c.checkinDate.year, c.checkinDate.month, c.checkinDate.day);
            return c.userId == myId && d == todayKey;
          });

    return _Card(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Daily check-in',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  checkedInToday
                      ? 'You already checked in today.'
                      : 'Check in once per day to build momentum.',
                  style: TextStyle(
                    color: TribeColors.muted(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: (_saving || checkedInToday) ? null : _checkIn,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(checkedInToday ? 'Done' : 'Check in'),
          ),
        ],
      ),
    );
  }
}

class _TodayCheckins extends ConsumerWidget {
  const _TodayCheckins({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(groupCheckinsProvider(groupId));
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return checkinsAsync.when(
      data: (checkins) {
        final todayCheckins = checkins.where((c) {
          final d = DateTime(c.checkinDate.year, c.checkinDate.month, c.checkinDate.day);
          return d == todayKey;
        }).toList(growable: false);

        if (todayCheckins.isEmpty) {
          return _Card(
            child: Text(
              'No check-ins yet today.',
              style: TextStyle(color: TribeColors.muted(context)),
            ),
          );
        }

        return _Card(
          child: Column(
            children: todayCheckins.take(10).map((c) {
              final alias = anonymousNameFor(c.userId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    _Avatar(seed: c.userId),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            alias,
                            style: TextStyle(
                              color: TribeColors.textPrimary(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (c.note != null && c.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              c.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  TextStyle(color: TribeColors.muted(context)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      Formatters.timeAgo(c.createdAt),
                      style: TextStyle(
                        color: TribeColors.muted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        );
      },
      loading: () => const _Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _Card(
        child: Text(
          error.toString(),
          style: TextStyle(color: TribeColors.muted(context)),
        ),
      ),
    );
  }
}

class _StreakBoard extends ConsumerWidget {
  const _StreakBoard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(groupCheckinsProvider(groupId));
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    return checkinsAsync.when(
      data: (checkins) {
        if (checkins.isEmpty) {
          return _Card(
            child: Text(
              'No streaks yet.',
              style: TextStyle(color: TribeColors.muted(context)),
            ),
          );
        }

        final byUser = <String, Set<DateTime>>{};
        for (final c in checkins) {
          final day = DateTime(c.checkinDate.year, c.checkinDate.month, c.checkinDate.day);
          (byUser[c.userId] ??= <DateTime>{}).add(day);
        }

        int streakFor(Set<DateTime> days) {
          var streak = 0;
          var d = todayKey;
          while (days.contains(d)) {
            streak += 1;
            d = d.subtract(const Duration(days: 1));
          }
          return streak;
        }

        final rows = byUser.entries
            .map((e) => (userId: e.key, streak: streakFor(e.value)))
            .toList(growable: false)
          ..sort((a, b) => b.streak.compareTo(a.streak));

        return _Card(
          child: Column(
            children: rows.take(8).map((row) {
              final alias = anonymousNameFor(row.userId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: <Widget>[
                    _Avatar(seed: row.userId),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alias,
                        style: TextStyle(
                          color: TribeColors.textPrimary(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '🔥 ${row.streak}d',
                      style: TextStyle(
                        color: TribeColors.textPrimary(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        );
      },
      loading: () => const _Card(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _Card(
        child: Text(
          error.toString(),
          style: TextStyle(color: TribeColors.muted(context)),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();
    final colorA = HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
    final colorB = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.55, 0.45).toColor();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colorA,
            colorB,
          ],
        ),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({
    required this.title,
    required this.seed,
    this.imageUrl,
    this.size = 46,
  });

  final String title;
  final String seed;
  final String? imageUrl;
  final double size;

  String _initials(String input) {
    final parts = input
        .trim()
        .split(RegExp(r'\\s+'))
        .where((p) => p.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'G';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    final a = parts[0].characters.first.toUpperCase();
    final b = parts[1].characters.first.toUpperCase();
    return '$a$b';
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(context),
        ),
      );
    }
    return _fallback(context);
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final t = (hash % 100) / 100.0;
    final a = Color.lerp(scheme.primary, scheme.secondary, 0.18 + (0.58 * t))!;
    final b = Color.lerp(scheme.secondary, scheme.primary, 0.12 + (0.44 * t))!;
    final initials = _initials(title);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[a, b],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: TribeColors.field(context),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 14, color: TribeColors.muted(context)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TribeColors.textPrimary(context),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
