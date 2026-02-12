import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../model/community_models.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _controller = TextEditingController();
  final _messages = <ChatMessage>[
    const ChatMessage(
        fromAlias: 'Axiom-23',
        text: 'Stay steady tonight. Peak window is temporary.',
        isMe: false),
    const ChatMessage(
        fromAlias: 'You',
        text: 'Thanks. Running the 90-second reset now.',
        isMe: true),
    const ChatMessage(
        fromAlias: 'Cipher-11',
        text: 'Good. Name the trigger and reduce scope.',
        isMe: false),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(fromAlias: 'You', text: text, isMe: true));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DisciplineScaffold(
      title: 'Private Chat',
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
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
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: Text(m.text, style: DisciplineTextStyles.body),
                    ),
                  ],
                );
              },
            ),
          ),
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
