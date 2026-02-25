import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/user_challenge.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

class GroupMembersScreen extends ConsumerWidget {
  const GroupMembersScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final groupAsync = ref.watch(groupProvider(groupId));
    final myMembershipAsync = ref.watch(userChallengesProvider);

    UserChallenge? myMembership;
    final myMemberships = myMembershipAsync.asData?.value;
    if (myMemberships != null) {
      for (final item in myMemberships) {
        if (item.challengeId == groupId) {
          myMembership = item;
          break;
        }
      }
    }
    final isAdmin = myMembership?.isAdmin ?? false;

    final groupTitle = groupAsync.asData?.value?.title ?? 'Group';

    if (session == null) {
      return Scaffold(
        backgroundColor: TribeColors.bgTop(context),
        appBar: AppBar(title: const Text('Members')),
        body: Center(
          child: Text(
            'Sign in to manage members.',
            style: TextStyle(color: TribeColors.muted(context)),
          ),
        ),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: TribeColors.bgTop(context),
        appBar: AppBar(title: const Text('Members')),
        body: Center(
          child: Text(
            'Only group admins can manage members.',
            style: TextStyle(color: TribeColors.muted(context)),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      backgroundColor: TribeColors.bgTop(context),
      appBar: AppBar(
        title: Text('$groupTitle members'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final userId = await showDialog<String?>(
            context: context,
            builder: (context) => const _AddMemberDialog(),
          );

          final trimmed = userId?.trim();
          if (trimmed == null || trimmed.isEmpty) return;

          try {
            await ref.read(challengesRepositoryProvider).addGroupMember(
                  groupId: groupId,
                  userId: trimmed,
                );
            ref.invalidate(groupMembersProvider(groupId));
            ref.invalidate(groupProvider(groupId));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member added.')),
              );
            }
          } catch (error, stackTrace) {
            AppLogger.error('groupMembers.add', error, stackTrace);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          }
        },
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Add'),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Text(
                'No members found.',
                style: TextStyle(color: TribeColors.muted(context)),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = member.userId == session.user.id;
              final canRemove = !isMe && !member.isAdmin;
              final title = anonymousNameFor(member.userId);

              return Container(
                decoration: BoxDecoration(
                  color: TribeColors.card(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: TribeColors.cardBorder(context)),
                ),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    member.isAdmin ? 'Admin' : 'Member',
                    style: TextStyle(color: TribeColors.muted(context)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (isMe)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                TribeColors.chip(context).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: TribeColors.cardBorder(context),
                            ),
                          ),
                          child: Text(
                            'You',
                            style: TextStyle(
                              color: TribeColors.muted(context),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (member.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: TribeColors.accent(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: TribeColors.accent(context)
                                  .withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: TribeColors.accent(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (canRemove) ...<Widget>[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Remove member',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove member?'),
                                content: Text(
                                  'Remove $title from this group?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => context.pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      foregroundColor:
                                          Theme.of(context).colorScheme.onError,
                                    ),
                                    onPressed: () => context.pop(true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            try {
                              await ref
                                  .read(challengesRepositoryProvider)
                                  .removeGroupMember(
                                    groupId: groupId,
                                    userId: member.userId,
                                  );
                              ref.invalidate(groupMembersProvider(groupId));
                              ref.invalidate(groupProvider(groupId));
                              HapticFeedback.selectionClick();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Member removed.'),
                                ),
                              );
                            } catch (error, stackTrace) {
                              AppLogger.error(
                                  'groupMembers.remove', error, stackTrace);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          icon: Icon(
                            Icons.person_remove_alt_1_outlined,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed: $error',
              style: TextStyle(color: TribeColors.muted(context)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    context.pop(value.isEmpty ? null : value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add member'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Paste user ID (UUID)',
        ),
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => context.pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
