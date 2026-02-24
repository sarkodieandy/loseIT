import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/formatters.dart';
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
    } catch (error, stackTrace) {
      AppLogger.error('community.reply', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(widget.postId));
    final repliesAsync = ref.watch(communityRepliesProvider(widget.postId));

    return Scaffold(
      backgroundColor: TribeColors.bgTop(context),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Replies'),
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
                    TribeColors.bgTop(context),
                    TribeColors.bgBottom(context),
                  ],
                ),
              ),
            ),
          ),
          Column(
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
                    final header = streak.isEmpty ? 'Anon' : 'Anon • $streak';
                    final badge = (post.badge?.trim().isNotEmpty ?? false)
                        ? post.badge!.trim()
                        : null;
                    return _ThreadCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _ThreadAvatar(seed: post.userId),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      header,
                                      style: TextStyle(
                                        color: Colors.white,
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
                              color: Colors.white,
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
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      itemBuilder: (context, index) {
                        final reply = replies[index];
                        return _ThreadCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'Anon',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    Formatters.timeAgo(reply.createdAt),
                                    style: TextStyle(
                                      color: TribeColors.muted(context),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                reply.content,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
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
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendReply(),
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Write a reply…',
                            hintStyle:
                                TextStyle(color: TribeColors.muted(context)),
                            filled: true,
                            fillColor: TribeColors.field(context),
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
                        onTap: _sending ? null : _sendReply,
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: TribeColors.accent(context),
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
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TribeColors.card(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: TribeColors.cardBorder(context)),
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

class _ThreadAvatar extends StatelessWidget {
  const _ThreadAvatar({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final hue = (hash % 360).toDouble();
    final colorA = HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
    final colorB = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.55, 0.45).toColor();

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
      child: const Icon(Icons.person, color: Colors.black, size: 22),
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TribeColors.cardBorder(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
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
