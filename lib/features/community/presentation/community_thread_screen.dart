import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/community_reply.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

class CommunityThreadScreen extends ConsumerStatefulWidget {
  const CommunityThreadScreen({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  ConsumerState<CommunityThreadScreen> createState() =>
      _CommunityThreadScreenState();
}

class _CommunityThreadScreenState extends ConsumerState<CommunityThreadScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (_sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to reply.')),
      );
      return;
    }
    final profile = ref.read(profileControllerProvider).asData?.value;
    if (profile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete onboarding before replying.')),
      );
      context.go('/onboarding');
      return;
    }

    setState(() => _sending = true);
    try {
      final alias = anonymousNameFor(session.user.id);
      await ref.read(communityRepositoryProvider).createReply(
            postId: widget.postId,
            content: text,
            anonymousName: alias,
          );
      _controller.clear();
      _hasText = false;
    } catch (error, stackTrace) {
      AppLogger.error('community.reply', error, stackTrace);
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
    final postAsync = ref.watch(communityPostProvider(widget.postId));
    final repliesAsync = ref.watch(communityRepliesProvider(widget.postId));
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final session = ref.watch(sessionProvider);
    final currentUserId = session?.user.id;
    final profile = ref.watch(profileControllerProvider).asData?.value;
    final canCompose = session != null && profile != null && !_sending;
    final canSend = canCompose && _hasText;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TribeColors.bgTop(context),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Replies'),
      ),
      body: Column(
        children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: postAsync.when(
                  data: (post) {
                    if (post == null) {
                      return _ThreadCard(
                        child: Text(
                          'Post not found.',
                          style: TextStyle(color: TribeColors.muted(context)),
                        ),
                      );
                    }
                    final streak = _streakText(
                        post.category, post.streakDays, post.streakLabel);
                    final rawName = post.anonymousName.trim();
                    final name = (currentUserId != null &&
                            post.userId == currentUserId)
                        ? 'You'
                        : (rawName.isEmpty ? 'Anon' : rawName);
                    final header = streak.isEmpty ? name : '$name • $streak';
                    final badge = (post.badge?.trim().isNotEmpty ?? false)
                        ? post.badge!.trim()
                        : null;
                    return _ThreadCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _ThreadAvatar(seed: post.userId, label: name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      header,
                                      style: TextStyle(
                                        color: TribeColors.textPrimary(context),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(post.topic?.trim().isNotEmpty ?? false) ? post.topic!.trim() : 'General'} · ${Formatters.timeAgo(post.createdAt)}',
                                      style: TextStyle(
                                        color: TribeColors.muted(context),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (badge != null) _ThreadBadge(label: badge),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post.content,
                            style: TextStyle(
                              color: TribeColors.textPrimary(context),
                              fontSize: 16,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => _ThreadCard(
                    child: Text(
                      'Loading post…',
                      style: TextStyle(color: TribeColors.muted(context)),
                    ),
                  ),
                  error: (error, _) => _ThreadCard(
                    child: Text(
                      'Error: $error',
                      style: TextStyle(color: TribeColors.muted(context)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: repliesAsync.when(
                  data: (replies) {
                    if (replies.isEmpty) {
                      return Center(
                        child: Text(
                          'No replies yet.',
                          style: TextStyle(color: TribeColors.muted(context)),
                        ),
                      );
                    }
                    final postUserId = postAsync.asData?.value?.userId;
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemBuilder: (context, index) {
                        final reply = replies[index];
                        return _ReplyTile(
                          reply: reply,
                          currentUserId: currentUserId,
                          postUserId: postUserId,
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: replies.length,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed: $error',
                      style: TextStyle(color: TribeColors.muted(context)),
                    ),
                  ),
                ),
              ),
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
                      color: TribeColors.card(context)
                          .withValues(alpha: isDark ? 0.92 : 0.96),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: TribeColors.cardBorder(context)),
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
                            textCapitalization: TextCapitalization.sentences,
                            minLines: 1,
                            maxLines: 4,
                            enabled: canCompose,
                            onChanged: (value) {
                              final hasText = value.trim().isNotEmpty;
                              if (hasText == _hasText) return;
                              setState(() => _hasText = hasText);
                            },
                            onSubmitted: (_) {
                              if (canSend) _sendReply();
                            },
                            style: TextStyle(
                              color: TribeColors.textPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: session == null
                                  ? 'Sign in to reply…'
                                  : (profile == null
                                      ? 'Complete onboarding to reply…'
                                      : 'Write a reply…'),
                              hintStyle:
                                  TextStyle(color: TribeColors.muted(context)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: canSend ? _sendReply : null,
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOut,
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? TribeColors.accent(context)
                                  : TribeColors.field(context),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: canSend
                                    ? onAccent.withValues(alpha: 0.18)
                                    : TribeColors.cardBorder(context),
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
                                            ? onAccent
                                            : TribeColors.muted(context),
                                      ),
                                    )
                                  : Icon(
                                      Icons.arrow_upward_rounded,
                                      color: canSend
                                          ? onAccent
                                          : TribeColors.muted(context),
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
    );
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.child});

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

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({
    required this.seed,
    this.label,
  });

  final String seed;
  final String? label;

  String _initialsFrom(String? raw) {
    if (raw == null) return '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final caps = RegExp(r'[A-Z]').allMatches(trimmed).map((m) => m.group(0)!);
    final capList = caps.toList(growable: false);
    if (capList.length >= 2) return '${capList[0]}${capList[1]}';
    final compact = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (compact.isEmpty) return '';
    if (compact.length == 1) return compact.toUpperCase();
    return compact.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();
    final colorA = HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
    final colorB = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.55, 0.45).toColor();
    final initials = _initialsFrom(label);

    return Container(
      width: 44,
      height: 44,
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
      child: initials.isNotEmpty
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  fontSize: 14,
                ),
              ),
            )
          : const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }
}

class _ThreadBadge extends StatelessWidget {
  const _ThreadBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TribeColors.chip(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TribeColors.cardBorder(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: TribeColors.textPrimary(context),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.reply,
    required this.currentUserId,
    required this.postUserId,
  });

  final CommunityReply reply;
  final String? currentUserId;
  final String? postUserId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mine = currentUserId != null && reply.userId == currentUserId;
    final isOp = postUserId != null && reply.userId == postUserId;
    final time = Formatters.timeAgo(reply.createdAt);
    final rawName = reply.anonymousName.trim();
    final name = mine ? 'You' : (rawName.isEmpty ? 'Anon' : rawName);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ThreadAvatar(seed: reply.userId, label: name),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: TribeColors.card(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: TribeColors.cardBorder(context)),
              boxShadow: isDark
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: <Widget>[
                          Text(
                            name,
                            style: TextStyle(
                              color: TribeColors.textPrimary(context),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          if (isOp) const _RolePill(label: 'OP'),
                        ],
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: TribeColors.muted(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  reply.content,
                  style: TextStyle(
                    color: TribeColors.textPrimary(context),
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TribeColors.chip(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TribeColors.cardBorder(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: TribeColors.muted(context),
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

String _streakText(String? category, int? streakDays, String? streakLabel) {
  final normalized = (category ?? '').toLowerCase();
  if (normalized == 'relapse') {
    final trimmed = streakLabel?.trim();
    return (trimmed != null && trimmed.isNotEmpty) ? trimmed : 'Reset';
  }
  if (streakDays != null) {
    if (streakDays <= 0) return 'Day 0';
    if (streakDays == 1) return 'Day 1';
    return '$streakDays days';
  }
  final trimmed = streakLabel?.trim();
  return (trimmed != null && trimmed.isNotEmpty) ? trimmed : '';
}
