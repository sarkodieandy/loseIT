import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/navigation/discipline_page_route.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../services/supabase/supabase_error_text.dart';
import '../../model/community_models.dart';
import 'private_chat_screen.dart';

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({
    super.key,
    required this.post,
    required this.isMine,
  });

  final CommunityPost post;
  final bool isMine;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _scrollController = ScrollController();
  final _composerController = TextEditingController();
  final _composerFocus = FocusNode();

  bool _loading = true;
  bool _sending = false;
  bool _hasText = false;
  String? _error;
  List<CommunityPostReply> _replies = const <CommunityPostReply>[];

  @override
  void initState() {
    super.initState();
    _composerController.addListener(_onComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _onComposerChanged() {
    final nextHasText = _composerController.text.trim().isNotEmpty;
    if (nextHasText == _hasText) return;
    setState(() => _hasText = nextHasText);
  }

  @override
  void dispose() {
    _composerController.removeListener(_onComposerChanged);
    _scrollController.dispose();
    _composerController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  String _initials(String alias) {
    final parts = alias
        .split(RegExp(r'[-_\\s]+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  String _timeAgo(int minutesAgo) {
    if (minutesAgo < 1) return 'just now';
    if (minutesAgo < 60) return '$minutesAgo min';
    final hours = (minutesAgo / 60).floor();
    if (hours < 24) return '$hours hr';
    final days = (hours / 24).floor();
    return '${days}d';
  }

  Color _badgeColor(CommunityPostKind kind) {
    return switch (kind) {
      CommunityPostKind.checkIn => DisciplineColors.accent.withValues(alpha: 0.16),
      CommunityPostKind.win => DisciplineColors.success.withValues(alpha: 0.16),
      CommunityPostKind.relapse => DisciplineColors.danger.withValues(alpha: 0.16),
      CommunityPostKind.advice => DisciplineColors.surface2.withValues(alpha: 0.75),
    };
  }

  Color _badgeBorderColor(CommunityPostKind kind) {
    return switch (kind) {
      CommunityPostKind.checkIn => DisciplineColors.accent.withValues(alpha: 0.45),
      CommunityPostKind.win => DisciplineColors.success.withValues(alpha: 0.45),
      CommunityPostKind.relapse => DisciplineColors.danger.withValues(alpha: 0.45),
      CommunityPostKind.advice => DisciplineColors.border.withValues(alpha: 0.7),
    };
  }

  Color _badgeTextColor(CommunityPostKind kind) {
    return switch (kind) {
      CommunityPostKind.checkIn => DisciplineColors.accent,
      CommunityPostKind.win => DisciplineColors.success,
      CommunityPostKind.relapse => DisciplineColors.danger,
      CommunityPostKind.advice => DisciplineColors.textSecondary,
    };
  }

  String _postBadgeLabel() {
    final explicit = widget.post.label?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    return switch (widget.post.kind) {
      CommunityPostKind.checkIn => widget.post.streakDays > 0
          ? 'Day ${widget.post.streakDays} checkpoint'
          : 'Daily pledge',
      CommunityPostKind.win => 'Milestone',
      CommunityPostKind.relapse =>
        widget.post.streakDays <= 0 ? 'Day 0' : '${widget.post.streakDays} Day Streak',
      CommunityPostKind.advice => 'Advice',
    };
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final app = AppScope.of(context);
    try {
      final replies = await app.services.community.fetchReplies(
        postId: widget.post.id,
      );
      if (!mounted) return;
      setState(() {
        _replies = replies;
        _loading = false;
      });
    } catch (error, stackTrace) {
      AppLogger.error('ThreadScreen.load', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _error = supabaseErrorText(error);
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = _composerController.text.trim();
    if (text.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });

    final app = AppScope.of(context);
    try {
      final created = await app.services.community.createReply(
        postId: widget.post.id,
        message: text,
        streakDays: app.state.streakDays,
      );

      if (!mounted) return;
      _composerController.clear();
      setState(() {
        _replies = <CommunityPostReply>[..._replies, created];
      });

      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error('ThreadScreen.send', error, stackTrace);
      if (!mounted) return;
      setState(() => _error = supabaseErrorText(error));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _focusComposer() {
    _composerFocus.requestFocus();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _openDirectSupport() {
    if (widget.isMine) return;

    final seed = ChatMessage(
      fromAlias: widget.post.alias,
      text: widget.post.message,
      isMe: false,
    );

    Navigator.of(context).push(
      DisciplinePageRoute<void>(
        builder: (_) => PrivateChatScreen(
          peerAlias: widget.post.alias,
          initialReplyTo: seed,
        ),
      ),
    );
  }

  Future<void> _showMore() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.post.message));
              Navigator.of(popupContext).pop();
            },
            child: const Text('Copy post'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.post.alias));
              Navigator.of(popupContext).pop();
            },
            child: const Text('Copy alias'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(popupContext).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentsCount =
        (_loading || (_error != null && _replies.isEmpty))
            ? widget.post.commentCount
            : _replies.length;
    final topic = (widget.post.topic == null || widget.post.topic!.trim().isEmpty)
        ? widget.post.kind.label
        : widget.post.topic!.trim();
    final streakLabel =
        widget.post.streakDays <= 0 ? 'Reset' : 'Day ${widget.post.streakDays}';

    Widget actionButton({
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
      bool highlighted = false,
    }) {
      final color = highlighted
          ? DisciplineColors.accent
          : DisciplineColors.textSecondary;
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Row(
          children: <Widget>[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: DisciplineTextStyles.caption.copyWith(
                color: color,
                fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    Widget postHeader() {
      return DisciplineCard(
        shadow: false,
        padding: const EdgeInsets.all(16),
        color: DisciplineColors.surface.withValues(alpha: 0.72),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DisciplineColors.surface2.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DisciplineColors.border.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Text(
                    _initials(widget.post.alias),
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
                        '${widget.post.alias} • $streakLabel',
                        style: DisciplineTextStyles.section.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$topic • ${_timeAgo(widget.post.minutesAgo)} ago',
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
                    color: _badgeColor(widget.post.kind),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _badgeBorderColor(widget.post.kind),
                    ),
                  ),
                  child: Text(
                    _postBadgeLabel(),
                    style: DisciplineTextStyles.caption.copyWith(
                      color: _badgeTextColor(widget.post.kind),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.post.message,
              style: DisciplineTextStyles.body.copyWith(
                fontSize: 20,
                height: 1.38,
                letterSpacing: -0.25,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  '${widget.post.supportCount} ',
                  style: DisciplineTextStyles.section.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Likes',
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  '$commentsCount ',
                  style: DisciplineTextStyles.section.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Comments',
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: DisciplineColors.border.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                actionButton(
                  icon: CupertinoIcons.heart,
                  label: 'Like',
                  onPressed: null,
                ),
                const SizedBox(width: 28),
                actionButton(
                  icon: CupertinoIcons.chat_bubble,
                  label: 'Reply',
                  onPressed: _focusComposer,
                ),
                const Spacer(),
                actionButton(
                  icon: CupertinoIcons.bolt,
                  label: 'Send Strength',
                  highlighted: true,
                  onPressed: widget.isMine ? null : _openDirectSupport,
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget replyTile(CommunityPostReply reply) {
      final replyStreak =
          reply.streakDays <= 0 ? 'Reset' : 'Day ${reply.streakDays}';
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
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
                _initials(reply.alias),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${reply.alias} • $replyStreak',
                          style: DisciplineTextStyles.section.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _timeAgo(reply.minutesAgo),
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reply.message,
                    style: DisciplineTextStyles.body.copyWith(
                      fontSize: 17,
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Text(
                        'Reply',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Text(
                        'Like',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget repliesSection() {
      if (_loading) {
        return const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 18),
            child: Center(child: CupertinoActivityIndicator()),
          ),
        );
      }

      if (_error != null && _replies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: DisciplineCard(
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Unable to load replies.',
                    style: DisciplineTextStyles.section.copyWith(
                      color: DisciplineColors.danger,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: DisciplineTextStyles.caption.copyWith(
                      color: DisciplineColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DisciplineButton(
                    label: 'Retry',
                    variant: DisciplineButtonVariant.secondary,
                    onPressed: _load,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (_replies.isEmpty) {
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Be the first to comment.',
              style: DisciplineTextStyles.caption.copyWith(
                color: DisciplineColors.textSecondary,
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => replyTile(_replies[index]),
          childCount: _replies.length,
        ),
      );
    }

    Widget composer() {
      final canSend = !_sending && _hasText;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: CupertinoTextField(
                  controller: _composerController,
                  focusNode: _composerFocus,
                  placeholder: 'Write a supportive comment…',
                  style: DisciplineTextStyles.body,
                  placeholderStyle: DisciplineTextStyles.secondary,
                  cursorColor: DisciplineColors.accent,
                  decoration: BoxDecoration(
                    color: DisciplineColors.surface2.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: DisciplineColors.border.withValues(alpha: 0.72),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  keyboardType: TextInputType.multiline,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: canSend ? _send : null,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DisciplineColors.accent.withValues(
                      alpha: canSend ? 1 : 0.35,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: canSend
                        ? <BoxShadow>[
                            BoxShadow(
                              color: DisciplineColors.accentGlow
                                  .withValues(alpha: 0.55),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    CupertinoIcons.paperplane_fill,
                    size: 18,
                    color: DisciplineColors.background,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DisciplineScaffold(
      title: 'Thread',
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: _showMore,
        child: const Icon(
          CupertinoIcons.ellipsis,
          size: 22,
          color: DisciplineColors.textSecondary,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: <Widget>[
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: <Widget>[
                CupertinoSliverRefreshControl(onRefresh: _load),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: postHeader(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 22)),
                const SliverToBoxAdapter(
                  child: Text(
                    'REPLIES',
                    style: DisciplineTextStyles.caption,
                  ),
                ),
                repliesSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
          if (_error != null && _replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: DisciplineTextStyles.caption.copyWith(
                  color: DisciplineColors.danger,
                ),
              ),
            ),
          composer(),
        ],
      ),
    );
  }
}
