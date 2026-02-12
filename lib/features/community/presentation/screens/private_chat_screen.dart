import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../model/community_models.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({
    super.key,
    this.group,
    this.peerAlias,
    this.initialReplyTo,
  }) : assert(group != null || peerAlias != null);

  final CommunityGroup? group;
  final String? peerAlias;
  final ChatMessage? initialReplyTo;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _controller = TextEditingController();
  late final List<ChatMessage> _messages = _seedMessages();
  ChatMessage? _replyingTo;

  List<ChatMessage> _seedMessages() {
    final peerAlias = widget.peerAlias;
    if (peerAlias != null) {
      return <ChatMessage>[
        ChatMessage(
          fromAlias: peerAlias,
          text: 'Checking in. How are you handling tonight?',
          isMe: false,
        ),
        const ChatMessage(
          fromAlias: 'You',
          text: 'Stable right now. Using the reset flow.',
          isMe: true,
        ),
      ];
    }

    return const <ChatMessage>[
      ChatMessage(
        fromAlias: 'Axiom-23',
        text: 'Stay steady tonight. Peak window is temporary.',
        isMe: false,
      ),
      ChatMessage(
        fromAlias: 'You',
        text: 'Thanks. Running the 90-second reset now.',
        isMe: true,
      ),
      ChatMessage(
        fromAlias: 'Cipher-11',
        text: 'Good. Name the trigger and reduce scope.',
        isMe: false,
      ),
    ];
  }

  String get _title {
    final peerAlias = widget.peerAlias;
    if (peerAlias != null) {
      return 'Chat • $peerAlias';
    }
    return 'Private Chat';
  }

  @override
  void initState() {
    super.initState();
    _replyingTo = widget.initialReplyTo;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startReply(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          fromAlias: 'You',
          text: text,
          isMe: true,
          replyToAlias: _replyingTo?.fromAlias,
          replyToText: _replyingTo?.text,
        ),
      );
      _controller.clear();
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final directAlias = widget.peerAlias;

    return DisciplineScaffold(
      title: _title,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          if (directAlias != null) ...[
            const SizedBox(height: 8),
            DisciplineCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shadow: false,
              color: DisciplineColors.surface.withValues(alpha: 0.7),
              borderColor: DisciplineColors.accent.withValues(alpha: 0.35),
              child: Row(
                children: <Widget>[
                  const Icon(
                    CupertinoIcons.person_crop_circle_badge_checkmark,
                    size: 16,
                    color: DisciplineColors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct chat with $directAlias',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final m = _messages[index];
                final align =
                    m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
                final bg = m.isMe
                    ? DisciplineColors.accent.withValues(alpha: 0.14)
                    : DisciplineColors.surface2;
                final border = m.isMe
                    ? DisciplineColors.accent.withValues(alpha: 0.35)
                    : DisciplineColors.border.withValues(alpha: 0.7);

                return Column(
                  crossAxisAlignment: align,
                  children: <Widget>[
                    Text(
                      m.fromAlias,
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onLongPress: () => _startReply(m),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (m.replyToAlias != null &&
                                m.replyToText != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: DisciplineColors.background.withValues(
                                    alpha: 0.32,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: DisciplineColors.border
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      m.replyToAlias!,
                                      style:
                                          DisciplineTextStyles.caption.copyWith(
                                        color: DisciplineColors.textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      m.replyToText!,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          DisciplineTextStyles.caption.copyWith(
                                        color: DisciplineColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(m.text, style: DisciplineTextStyles.body),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    CupertinoButton(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      onPressed: () => _startReply(m),
                      child: Text(
                        'Reply',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.accent,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_replyingTo != null) ...[
            DisciplineCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shadow: false,
              color: DisciplineColors.surface.withValues(alpha: 0.7),
              borderColor: DisciplineColors.accent.withValues(alpha: 0.4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Replying to ${_replyingTo!.fromAlias}',
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.all(4),
                    onPressed: _cancelReply,
                    child: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 20,
                      color: DisciplineColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          DisciplineCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shadow: false,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: CupertinoTextField(
                    controller: _controller,
                    placeholder: 'Write a focused message…',
                    style: DisciplineTextStyles.body,
                    placeholderStyle: DisciplineTextStyles.secondary,
                    cursorColor: DisciplineColors.accent,
                    decoration: const BoxDecoration(color: Color(0x00000000)),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.all(6),
                  onPressed: _send,
                  child: const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: DisciplineColors.accent,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
