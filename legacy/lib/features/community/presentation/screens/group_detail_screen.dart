import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/navigation/discipline_page_route.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../model/community_models.dart';
import '../widgets/member_avatar.dart';
import 'private_chat_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key, required this.group});

  final CommunityGroup group;

  @override
  Widget build(BuildContext context) {
    return DisciplineScaffold(
      title: 'Group',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 18),
        children: <Widget>[
          Text(group.name, style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Anonymous performance support. Alias only.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          if (group.code.trim().isNotEmpty) ...[
            DisciplineCard(
              shadow: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Invite code',
                          style: DisciplineTextStyles.caption),
                      const SizedBox(height: 8),
                      Text(
                        group.code,
                        style: DisciplineTextStyles.section.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: group.code));
                    },
                    child: const Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 18,
                      color: DisciplineColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Members', style: DisciplineTextStyles.caption),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: group.members
                        .map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: MemberAvatar(
                              alias: m.alias,
                              streakDays: m.streakDays,
                              onTap: () {
                                Navigator.of(context).push(
                                  DisciplinePageRoute<void>(
                                    builder: (_) =>
                                        PrivateChatScreen(peerAlias: m.alias),
                                  ),
                                );
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap a member to open direct chat.',
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DisciplineCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Weekly change',
                        style: DisciplineTextStyles.caption),
                    const SizedBox(height: 8),
                    Text(
                      '+${group.weeklyChangePercent}%',
                      style: DisciplineTextStyles.section.copyWith(
                        fontWeight: FontWeight.w800,
                        color: DisciplineColors.accent,
                      ),
                    ),
                  ],
                ),
                Icon(
                  CupertinoIcons.chart_bar,
                  color: DisciplineColors.accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          DisciplineButton(
            label: 'Open Group Chat',
            onPressed: () {
              Navigator.of(context).push(
                DisciplinePageRoute<void>(
                  builder: (_) => PrivateChatScreen(group: group),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Serious layout. No reactions. No public identity.',
            style: DisciplineTextStyles.caption.copyWith(
              color: DisciplineColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
