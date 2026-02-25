import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/challenge.dart';
import '../../../data/models/group_checkin.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class DailyCheckinScreen extends ConsumerWidget {
  const DailyCheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final membershipsAsync = ref.watch(userChallengesProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily check-in')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: SectionCard(
            child: Text('Sign in to check in and stay accountable.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily check-in'),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.push('/emergency-sos'),
            child: const Text('SOS'),
          ),
        ],
      ),
      body: membershipsAsync.when(
        data: (memberships) {
          final joinedMemberships = memberships
              .where((m) => m.challengeId.trim().isNotEmpty)
              .toList(growable: false)
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

          if (joinedMemberships.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                const SectionCard(
                  child: Text(
                    'No groups yet.\n\nJoin a group so daily check-ins feel real and social.',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/community'),
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Explore groups'),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const SectionCard(
                child: Text(
                  'A 30‑second check‑in builds momentum.\nShow up today — even if it\'s messy.',
                  style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
              const SizedBox(height: 14),
              ...joinedMemberships.map(
                (membership) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final groupAsync =
                          ref.watch(groupProvider(membership.challengeId));
                      return groupAsync.when(
                        data: (group) {
                          if (group == null) {
                            return const SectionCard(
                              child: Text('Group not found.'),
                            );
                          }
                          return _GroupCheckinCard(group: group);
                        },
                        loading: () => const SectionCard(
                          child: SizedBox(
                            height: 72,
                            child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (error, _) => SectionCard(
                          child: Text('Failed to load group: $error'),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tip: if porn/scrolling is your trigger, check in before bedtime.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Failed to load memberships: $error'),
          ),
        ),
      ),
    );
  }
}

class _GroupCheckinCard extends ConsumerStatefulWidget {
  const _GroupCheckinCard({
    required this.group,
  });

  final Challenge group;

  @override
  ConsumerState<_GroupCheckinCard> createState() => _GroupCheckinCardState();
}

class _GroupCheckinCardState extends ConsumerState<_GroupCheckinCard> {
  bool _saving = false;

  Future<void> _checkIn() async {
    if (_saving) return;
    final noteController = TextEditingController();
    final note = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Check in • ${widget.group.title}'),
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
            onPressed: () => Navigator.of(context).pop(noteController.text),
            child: const Text('Check in'),
          ),
        ],
      ),
    );

    setState(() => _saving = true);
    try {
      final trimmed = (note ?? '').trim();
      await ref.read(challengesRepositoryProvider).createGroupCheckin(
            groupId: widget.group.id,
            note: trimmed.isEmpty ? null : trimmed,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checked in to ${widget.group.title}.')),
      );
    } catch (error, stackTrace) {
      AppLogger.error('daily_checkin.create', error, stackTrace);
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
    final checkinsAsync = ref.watch(groupCheckinsProvider(widget.group.id));

    final myId = session?.user.id;
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final checkins = checkinsAsync.asData?.value ?? const <GroupCheckin>[];
    final checkedInToday = myId == null
        ? false
        : checkins.any((c) {
            final d = DateTime(
              c.checkinDate.year,
              c.checkinDate.month,
              c.checkinDate.day,
            );
            return c.userId == myId && d == todayKey;
          });

    final schedule = (widget.group.description?.trim().isNotEmpty ?? false)
        ? widget.group.description!.trim()
        : null;

    return SectionCard(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.group.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  checkedInToday
                      ? 'You already checked in today.'
                      : 'Check in once per day to build momentum.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (schedule != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    schedule,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: (_saving || checkedInToday) ? null : _checkIn,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(checkedInToday ? 'Done' : 'Check in'),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Open group',
            onPressed: () => context.push('/groups/${widget.group.id}'),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
