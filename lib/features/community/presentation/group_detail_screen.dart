import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/group_checkin.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class _GroupColors {
  static const Color bgTop = Color(0xFF050607);
  static const Color bgBottom = Color(0xFF0B0E11);
  static const Color card = Color(0xFF0E1216);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color muted = Color(0xFF9AA3AB);
  static const Color accent = Color(0xFF26B7FF);
  static const Color chip = Color(0xFF0D1115);
}

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

    return Scaffold(
      backgroundColor: _GroupColors.bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Group'),
        actions: <Widget>[
          if (isJoined)
            TextButton(
              onPressed: () async {
                await ref.read(challengesRepositoryProvider).leaveGroup(groupId);
                ref.invalidate(userChallengesProvider);
                ref.invalidate(challengesProvider);
                if (context.mounted) context.pop();
              },
              style: TextButton.styleFrom(foregroundColor: _GroupColors.muted),
              child: const Text('Leave'),
            ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    _GroupColors.bgTop,
                    _GroupColors.bgBottom,
                  ],
                ),
              ),
            ),
          ),
          groupAsync.when(
            data: (group) {
              if (group == null) {
                return const Center(
                  child: Text(
                    'Group not found.',
                    style: TextStyle(color: _GroupColors.muted),
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
                        const _Avatar(seed: 'group'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                group.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$memberCount members',
                                style: const TextStyle(
                                  color: _GroupColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (schedule != null) ...[
                                const SizedBox(height: 6),
                                _Pill(label: schedule),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Card(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.chat_bubble_outline, color: _GroupColors.muted),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Group chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/groups/$groupId/chat'),
                          style: TextButton.styleFrom(
                            foregroundColor: _GroupColors.accent,
                          ),
                          child: const Text('Open'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ChatPreview(groupId: groupId),
                  const SizedBox(height: 18),
                  if (session == null)
                    const _Card(
                      child: Text(
                        'Sign in to join and check-in.',
                        style: TextStyle(color: _GroupColors.muted),
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
                                color: Colors.white,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _GroupColors.accent,
                              foregroundColor: Colors.black,
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
                  const Text(
                    'Today',
                    style: TextStyle(
                      color: _GroupColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TodayCheckins(groupId: groupId),
                  const SizedBox(height: 18),
                  const Text(
                    'Streak board',
                    style: TextStyle(
                      color: _GroupColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                  style: const TextStyle(color: _GroupColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
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
          return const _Card(
            child: Text(
              'No messages yet. Start the conversation.',
              style: TextStyle(color: _GroupColors.muted),
            ),
          );
        }

        final recent = messages.take(3).toList(growable: false);
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Recent messages',
                style: TextStyle(
                  color: _GroupColors.muted,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _GroupColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Formatters.timeAgo(m.createdAt),
                        style: const TextStyle(
                          color: _GroupColors.muted,
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
    } catch (error) {
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
                const Text(
                  'Daily check-in',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  checkedInToday
                      ? 'You already checked in today.'
                      : 'Check in once per day to build momentum.',
                  style: const TextStyle(
                    color: _GroupColors.muted,
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
              backgroundColor: _GroupColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
          return const _Card(
            child: Text(
              'No check-ins yet today.',
              style: TextStyle(color: _GroupColors.muted),
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (c.note != null && c.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              c.note!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _GroupColors.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      Formatters.timeAgo(c.createdAt),
                      style: const TextStyle(
                        color: _GroupColors.muted,
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
          style: const TextStyle(color: _GroupColors.muted),
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
          return const _Card(
            child: Text(
              'No streaks yet.',
              style: TextStyle(color: _GroupColors.muted),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '🔥 ${row.streak}d',
                      style: const TextStyle(
                        color: Colors.white,
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
          style: const TextStyle(color: _GroupColors.muted),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _GroupColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _GroupColors.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
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
      child: const Icon(Icons.person, color: Colors.black, size: 20),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _GroupColors.chip,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _GroupColors.cardBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
