import 'package:flutter/cupertino.dart';

import '../../../core/navigation/discipline_page_route.dart';
import '../../../core/theme/discipline_text_styles.dart';
import '../../../core/widgets/discipline_card.dart';
import '../../../core/widgets/discipline_scaffold.dart';
import '../model/community_models.dart';
import 'screens/group_detail_screen.dart';
import 'screens/join_create_group_sheet.dart';
import 'screens/private_chat_screen.dart';
import 'widgets/community_post_card.dart';

class CommunityHomeScreen extends StatelessWidget {
  const CommunityHomeScreen({super.key});

  List<CommunityPost> _posts() {
    return const <CommunityPost>[
      CommunityPost(
        alias: 'Axiom-23',
        streakDays: 14,
        message: 'Late-night window is my weak point. Lock Mode helped.',
        minutesAgo: 6,
      ),
      CommunityPost(
        alias: 'Cipher-11',
        streakDays: 21,
        message: 'I reduced scope: “next 60 seconds only.” It works.',
        minutesAgo: 18,
      ),
      CommunityPost(
        alias: 'Vector-5',
        streakDays: 6,
        message: 'Breathing reset prevented a spiral today.',
        minutesAgo: 44,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final posts = _posts();

    return DisciplineScaffold(
      title: 'Community',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          const Text('Anonymous support.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Alias only. Clean cards. No public identity.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            shadow: false,
            onTap: () async {
              final group = await showCupertinoModalPopup<CommunityGroup>(
                context: context,
                builder: (_) => const JoinCreateGroupSheet(),
              );
              if (group == null) return;
              if (!context.mounted) return;
              Navigator.of(context).push(
                DisciplinePageRoute<void>(
                  builder: (_) => GroupDetailScreen(group: group),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Join / Create Group',
                    style: DisciplineTextStyles.section),
                const Icon(CupertinoIcons.plus_circle),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Feed', style: DisciplineTextStyles.caption),
          const SizedBox(height: 10),
          ...posts.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CommunityPostCard(
                post: p,
                onReply: () {
                  final seed = ChatMessage(
                    fromAlias: p.alias,
                    text: p.message,
                    isMe: false,
                  );
                  Navigator.of(context).push(
                    DisciplinePageRoute<void>(
                      builder: (_) => PrivateChatScreen(
                        peerAlias: p.alias,
                        initialReplyTo: seed,
                      ),
                    ),
                  );
                },
                onChat: () {
                  Navigator.of(context).push(
                    DisciplinePageRoute<void>(
                      builder: (_) => PrivateChatScreen(peerAlias: p.alias),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
