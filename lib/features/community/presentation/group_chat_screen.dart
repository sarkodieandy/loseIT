import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/group_message.dart';
import '../../../data/services/local_cache_service.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/group_chat_unread_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

class _ChatColors {
  static Color bgTop(BuildContext context) => TribeColors.bgTop(context);
  static Color bgBottom(BuildContext context) => TribeColors.bgBottom(context);
  static Color card(BuildContext context) => TribeColors.card(context);
  static Color cardBorder(BuildContext context) => TribeColors.cardBorder(context);
  static Color muted(BuildContext context) => TribeColors.muted(context);
  static Color accent(BuildContext context) => TribeColors.accent(context);
  static Color field(BuildContext context) => TribeColors.field(context);
  static Color textPrimary(BuildContext context) => TribeColors.textPrimary(context);

  static Color mineBubble(BuildContext context) => TribeColors.accent(context);
  static Color otherBubble(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
}

class GroupChatScreen extends ConsumerStatefulWidget {
  const GroupChatScreen({
    super.key,
    required this.groupId,
  });

  final String groupId;

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _hasText = false;
  DateTime? _lastSeenUtc;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markSeen({
    required String userId,
    required DateTime seenAt,
  }) async {
    await LocalCacheService.instance.setGroupChatLastSeen(
      userId: userId,
      groupId: widget.groupId,
      seenAt: seenAt,
    );
    ref.invalidate(groupChatLastSeenProvider(widget.groupId));
  }

  Future<void> _send() async {
    if (_sending) return;
    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to chat.')),
      );
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      await ref.read(challengesRepositoryProvider).sendGroupMessage(
            groupId: widget.groupId,
            content: text,
          );
      _controller.clear();
      _hasText = false;
      HapticFeedback.selectionClick();
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.send', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _hasText = _controller.text.trim().isNotEmpty;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mark messages as seen whenever the latest message changes.
    ref.listen<AsyncValue<List<GroupMessage>>>(
      groupMessagesProvider(widget.groupId),
      (previous, next) {
        final session = ref.read(sessionProvider);
        final messages = next.asData?.value;
        if (session == null || messages == null || messages.isEmpty) return;
        final latestUtc = messages.first.createdAt.toUtc();
        if (_lastSeenUtc != null && !latestUtc.isAfter(_lastSeenUtc!)) return;
        _lastSeenUtc = latestUtc;
        unawaited(_markSeen(
          userId: session.user.id,
          seenAt: latestUtc,
        ));
      },
    );

    final session = ref.watch(sessionProvider);
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final joinedAsync = ref.watch(userChallengesProvider);
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));

    final isJoined = joinedAsync.asData?.value
            .any((item) => item.challengeId == widget.groupId) ??
        false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend = isJoined && session != null && !_sending && _hasText;

    return Scaffold(
      backgroundColor: _ChatColors.bgTop(context),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ChatColors.textPrimary(context),
        title: groupAsync.maybeWhen(
          data: (group) => Text(
            group?.title ?? 'Group chat',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => const Text('Group chat'),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    _ChatColors.bgTop(context),
                    _ChatColors.bgBottom(context),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: _InfoCard(
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.shield_outlined,
                        color: _ChatColors.muted(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Anonymous group chat. No names. No personal info.',
                          style: TextStyle(
                            color: _ChatColors.textPrimary(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isJoined
                              ? TribeColors.green(context).withValues(alpha: 0.14)
                              : TribeColors.chip(context),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isJoined
                                ? TribeColors.green(context)
                                    .withValues(alpha: 0.35)
                                : _ChatColors.cardBorder(context),
                          ),
                        ),
                        child: Text(
                          isJoined ? 'Member' : 'Join to chat',
                          style: TextStyle(
                            color: isJoined
                                ? TribeColors.green(context)
                                : _ChatColors.muted(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.forum_outlined,
                              size: 46,
                              color: _ChatColors.muted(context)
                                  .withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No messages yet.',
                              style:
                                  TextStyle(color: _ChatColors.muted(context)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to check in.',
                              style: TextStyle(
                                color: _ChatColors.muted(context)
                                    .withValues(alpha: 0.75),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = session?.user.id == message.senderId;
                        return _Bubble(
                          message: message,
                          mine: mine,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _friendlyError(error),
                        style: TextStyle(color: _ChatColors.muted(context)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              if (session == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Sign in to send messages.',
                      style: TextStyle(color: _ChatColors.muted(context)),
                    ),
                  ),
                )
              else if (!isJoined)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _ChatColors.accent(context),
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(challengesRepositoryProvider)
                              .startChallenge(widget.groupId);
                          ref.invalidate(userChallengesProvider);
                          ref.invalidate(challengesProvider);
                        },
                        child: const Text(
                          'Join group to chat',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SafeArea(
                  top: false,
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _ChatColors.card(context)
                            .withValues(alpha: isDark ? 0.92 : 0.96),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _ChatColors.cardBorder(context)),
                        boxShadow: isDark
                            ? null
                            : <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onChanged: (value) {
                                final hasText = value.trim().isNotEmpty;
                                if (hasText == _hasText) return;
                                setState(() => _hasText = hasText);
                              },
                              onSubmitted: (_) {
                                if (canSend) _send();
                              },
                              style: TextStyle(
                                color: _ChatColors.textPrimary(context),
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Message…',
                                hintStyle:
                                    TextStyle(color: _ChatColors.muted(context)),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: canSend ? _send : null,
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOut,
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: canSend
                                    ? _ChatColors.accent(context)
                                    : _ChatColors.field(context),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: canSend
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withValues(alpha: 0.18)
                                      : _ChatColors.cardBorder(context),
                                ),
                              ),
                              child: Center(
                                child: _sending
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: canSend
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                              : _ChatColors.muted(context),
                                        ),
                                      )
                                    : Icon(
                                        Icons.arrow_upward_rounded,
                                        color: canSend
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : _ChatColors.muted(context),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('relation \"public.group_messages\"') ||
        message.contains('group_messages')) {
      return 'Group chat backend is not set up yet.\n\n'
          'Run `supabase/schema.sql` in Supabase SQL Editor to create `group_messages` and policies.';
    }
    if (message.contains('violates row-level security policy') ||
        message.contains('permission denied')) {
      return 'Permission blocked by RLS.\n\nJoin the group first, and ensure RLS policies are installed.';
    }
    return 'Failed: $message';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ChatColors.card(context).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ChatColors.cardBorder(context)),
        boxShadow: isDark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
  });

  final GroupMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final alias = anonymousNameFor(message.senderId);
    final time = Formatters.timeAgo(message.createdAt);
    final bubbleColor =
        mine ? _ChatColors.mineBubble(context) : _ChatColors.otherBubble(context);
    final onMine = Theme.of(context).colorScheme.onPrimary;
    final textColor =
        mine ? onMine : TribeColors.textPrimary(context);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
              border: Border.all(
                color: mine
                    ? onMine.withValues(alpha: 0.18)
                    : _ChatColors.cardBorder(context),
              ),
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment:
                    mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  if (!mine)
                    Text(
                      alias,
                      style: TextStyle(
                        color: _ChatColors.muted(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  if (!mine) const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: textColor,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: mine
                          ? onMine.withValues(alpha: 0.75)
                          : _ChatColors.muted(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
