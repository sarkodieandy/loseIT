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

  static Color mineBubble(BuildContext context) => TribeColors.accent(context);
  static Color otherBubble(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF10161C)
          : const Color(0xFF10161C);
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
  DateTime? _lastSeenUtc;

  @override
  void initState() {
    super.initState();
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
  }

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
      HapticFeedback.selectionClick();
    } catch (error, stackTrace) {
      AppLogger.error('groupChat.send', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    final joinedAsync = ref.watch(userChallengesProvider);
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));

    final isJoined = joinedAsync.asData?.value
            .any((item) => item.challengeId == widget.groupId) ??
        false;

    return Scaffold(
      backgroundColor: _ChatColors.bgTop(context),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
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
                      Icon(Icons.shield_outlined, color: _ChatColors.muted(context)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Anonymous group chat. No names. No personal info.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        isJoined ? 'Member' : 'Join to chat',
                        style: const TextStyle(
                          color: _ChatColors.muted(context),
                          fontWeight: FontWeight.w700,
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
                        child: Text(
                          'No messages yet.',
                          style: TextStyle(color: _ChatColors.muted(context)),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                        style: TextStyle(color: _ChatColors.muted(context)(context)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              if (session == null)
                const SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.all(16),
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
                          foregroundColor: Colors.black,
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
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Message…',
                              hintStyle: TextStyle(color: _ChatColors.muted(context)),
                              filled: true,
                              fillColor: _ChatColors.field(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: _sending ? null : _send,
                          borderRadius: BorderRadius.circular(18),
                          child: Ink(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _ChatColors.accent(context),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: _sending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                        ),
                      ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _ChatColors.card(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _ChatColors.card(context)Border),
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
    final bubbleColor = mine ? _ChatColors.mineBubble : _ChatColors.otherBubble;
    final textColor = mine ? Colors.black : Colors.white;

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
                    ? Colors.black.withValues(alpha: 0.10)
                    : _ChatColors.card(context)Border,
              ),
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
                      style: const TextStyle(
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
                          ? Colors.black.withValues(alpha: 0.55)
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
