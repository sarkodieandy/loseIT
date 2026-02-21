import 'package:flutter/cupertino.dart';

import '../../../app/app_controller.dart';
import '../../../core/navigation/discipline_page_route.dart';
import '../../../core/theme/discipline_colors.dart';
import '../../../core/theme/discipline_text_styles.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/discipline_button.dart';
import '../../../core/widgets/discipline_card.dart';
import '../../../core/widgets/discipline_scaffold.dart';
import '../model/community_models.dart';
import 'screens/create_post_sheet.dart';
import 'screens/group_detail_screen.dart';
import 'screens/join_create_group_sheet.dart';
import 'screens/private_chat_screen.dart';
import 'screens/thread_screen.dart';
import 'widgets/community_post_card.dart';

enum _FeedFilter { all, checkIns, wins, relapses, advice }

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  List<CommunityPost> _posts = const <CommunityPost>[];
  List<CommunityGroup> _groups = const <CommunityGroup>[];
  String _myAlias = '';
  bool _loading = true;
  String? _error;
  bool _didLoad = false;

  bool _searching = false;
  String _query = '';
  _FeedFilter _filter = _FeedFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _loadCommunity();
  }

  Future<void> _loadCommunity() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final app = AppScope.of(context);
    try {
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        app.services.community.fetchFeed(),
        app.services.community.fetchMyGroups(),
        app.services.auth.currentAlias(),
      ]);
      final feed = results[0] as List<CommunityPost>;
      final groups = results[1] as List<CommunityGroup>;
      final alias = results[2] as String;
      if (!mounted) return;
      setState(() {
        _posts = feed;
        _groups = groups;
        _myAlias = alias;
      });
    } catch (error, stackTrace) {
      AppLogger.error('CommunityHomeScreen._loadCommunity', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<CommunityPost> get _filteredPosts {
    var items = _posts;

    items = switch (_filter) {
      _FeedFilter.all => items,
      _FeedFilter.checkIns =>
        items.where((p) => p.kind == CommunityPostKind.checkIn).toList(),
      _FeedFilter.wins =>
        items.where((p) => p.kind == CommunityPostKind.win).toList(),
      _FeedFilter.relapses =>
        items.where((p) => p.kind == CommunityPostKind.relapse).toList(),
      _FeedFilter.advice =>
        items.where((p) => p.kind == CommunityPostKind.advice).toList(),
    };

    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;

    bool matches(CommunityPost post) {
      final haystack = <String>[
        post.alias,
        post.message,
        post.topic ?? '',
        post.label ?? '',
        post.kind.label,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }

    return items.where(matches).toList(growable: false);
  }

  Future<void> _openJoinCreateGroup() async {
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
    await _loadCommunity();
  }

  Future<void> _openCreatePost() async {
    final app = AppScope.of(context);
    final created = await showCupertinoModalPopup<CommunityPost>(
      context: context,
      builder: (_) => CreatePostSheet(
        initialStreakDays: app.state.streakDays,
      ),
    );
    if (created == null) return;
    await _loadCommunity();
  }

  @override
  Widget build(BuildContext context) {
    final posts = _filteredPosts;

    Widget pill({
      required String label,
      required bool selected,
      required VoidCallback onPressed,
    }) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? DisciplineColors.accent.withValues(alpha: 0.22)
                : DisciplineColors.surface2.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? DisciplineColors.accent.withValues(alpha: 0.55)
                  : DisciplineColors.border.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            label,
            style: DisciplineTextStyles.caption.copyWith(
              color: selected
                  ? DisciplineColors.accent
                  : DisciplineColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    Widget header() {
      final subtitle = switch (_filter) {
        _FeedFilter.wins => 'Celebrating victories together.',
        _ => 'Anonymous support from people on the same path.',
      };

      Widget iconCircle(IconData icon, {required VoidCallback onPressed}) {
        return CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: onPressed,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DisciplineColors.surface.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: DisciplineColors.border.withValues(alpha: 0.65),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.28),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 20,
              color: DisciplineColors.textSecondary,
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Community',
                  style: DisciplineTextStyles.headline.copyWith(fontSize: 30),
                ),
              ),
              iconCircle(
                CupertinoIcons.search,
                onPressed: () => setState(() => _searching = !_searching),
              ),
              const SizedBox(width: 10),
              iconCircle(CupertinoIcons.plus, onPressed: _openCreatePost),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          if (_searching) ...[
            const SizedBox(height: 14),
            CupertinoSearchTextField(
              placeholder: 'Search posts…',
              backgroundColor: DisciplineColors.surface2.withValues(alpha: 0.75),
              onChanged: (value) => setState(() => _query = value),
              onSuffixTap: () => setState(() => _query = ''),
            ),
          ],
          const SizedBox(height: 18),
          const Text('Filters', style: DisciplineTextStyles.caption),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              pill(
                label: 'All',
                selected: _filter == _FeedFilter.all,
                onPressed: () => setState(() => _filter = _FeedFilter.all),
              ),
              pill(
                label: 'Check-ins',
                selected: _filter == _FeedFilter.checkIns,
                onPressed: () => setState(() => _filter = _FeedFilter.checkIns),
              ),
              pill(
                label: 'Wins',
                selected: _filter == _FeedFilter.wins,
                onPressed: () => setState(() => _filter = _FeedFilter.wins),
              ),
              pill(
                label: 'Relapses',
                selected: _filter == _FeedFilter.relapses,
                onPressed: () => setState(() => _filter = _FeedFilter.relapses),
              ),
              pill(
                label: 'Advice',
                selected: _filter == _FeedFilter.advice,
                onPressed: () => setState(() => _filter = _FeedFilter.advice),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      );
    }

    Widget groupsSection() {
      final groups = _groups;
      if (groups.isEmpty) {
        return DisciplineCard(
          shadow: false,
          onTap: _openJoinCreateGroup,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Join / Create group',
                style: DisciplineTextStyles.section,
              ),
              const Icon(CupertinoIcons.plus_circle),
            ],
          ),
        );
      }

      Widget groupCard(CommunityGroup group) {
        final count = group.members.length;
        final sizeLabel = count <= 8 ? 'Small group' : 'Habit builders';
        final subtitle = '$sizeLabel • $count members';
        final trend = group.weeklyChangePercent;

        final badgeText = trend == 0
            ? null
            : '${trend > 0 ? '+' : ''}$trend% this week';

        return DisciplineCard(
          shadow: false,
          onTap: () {
            Navigator.of(context).push(
              DisciplinePageRoute<void>(
                builder: (_) => GroupDetailScreen(group: group),
              ),
            );
          },
          padding: const EdgeInsets.all(14),
          color: DisciplineColors.surface.withValues(alpha: 0.72),
          child: SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DisciplineTextStyles.section.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: DisciplineColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: DisciplineColors.surface2.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: DisciplineColors.border.withValues(alpha: 0.75),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      Widget addGroupCard() {
        return DisciplineCard(
          shadow: false,
          onTap: _openJoinCreateGroup,
          padding: const EdgeInsets.all(14),
          color: DisciplineColors.surface2.withValues(alpha: 0.75),
          child: SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: DisciplineColors.accent,
                  size: 22,
                ),
                const SizedBox(height: 10),
                Text(
                  'Join / create',
                  style: DisciplineTextStyles.section.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find your circle.',
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16),
          const Text('Accountability groups', style: DisciplineTextStyles.caption),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                ...groups.map(
                  (g) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: groupCard(g),
                  ),
                ),
                addGroupCard(),
              ],
            ),
          ),
        ],
      );
    }

    Widget directSupportSection() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 16),
          const Text('Direct support', style: DisciplineTextStyles.caption),
          const SizedBox(height: 10),
          DisciplineCard(
            shadow: false,
            onTap: () {
              Navigator.of(context).push(
                DisciplinePageRoute<void>(
                  builder: (_) => const PrivateChatScreen(peerAlias: 'Coach'),
                ),
              );
            },
            child: Row(
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
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_fill,
                    color: DisciplineColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Coach session',
                        style: DisciplineTextStyles.section.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leave a note for your next 1:1',
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 18,
                  color: DisciplineColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget feedSection() {
      final title = switch (_filter) {
        _FeedFilter.checkIns => 'Latest Check-ins',
        _FeedFilter.relapses => 'Recent Shares',
        _FeedFilter.wins => 'Recent Wins',
        _FeedFilter.advice => 'Advice',
        _FeedFilter.all => 'Today in your circle',
      };

      if (posts.isEmpty) {
        return DisciplineCard(
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'No posts yet.',
                style: DisciplineTextStyles.section.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share a focused update so others can support you.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 12),
              DisciplineButton(
                label: 'Create post',
                onPressed: _openCreatePost,
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: DisciplineTextStyles.caption),
          const SizedBox(height: 10),
          if (_filter == _FeedFilter.wins) ...[
            DisciplineCard(
              shadow: false,
              padding: const EdgeInsets.all(14),
              color: DisciplineColors.surface2.withValues(alpha: 0.75),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DisciplineColors.success.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DisciplineColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.rosette,
                      size: 20,
                      color: DisciplineColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${posts.where((p) => p.minutesAgo < 1440).length} Wins Today',
                          style: DisciplineTextStyles.section.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The community is staying strong.',
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...posts.map((p) {
            final isMine = _myAlias.isNotEmpty && p.alias == _myAlias;
            final action = switch (p.kind) {
              CommunityPostKind.advice => 'Share advice',
              CommunityPostKind.checkIn => 'Encourage',
              CommunityPostKind.win => 'Congratulate',
              CommunityPostKind.relapse => 'Send strength',
            };

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CommunityPostCard(
                post: p,
                actionLabel: isMine ? null : '$action ↗',
                onTap: () {
                  Navigator.of(context).push(
                    DisciplinePageRoute<void>(
                      builder: (_) => ThreadScreen(post: p, isMine: isMine),
                    ),
                  );
                },
                onAction: isMine
                    ? null
                    : () {
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
              ),
            );
          }),
        ],
      );
    }

    return DisciplineScaffold(
      title: null,
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverRefreshControl(onRefresh: _loadCommunity),
          SliverToBoxAdapter(child: header()),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: DisciplineCard(
                shadow: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Unable to load community.',
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
                      onPressed: _loadCommunity,
                    ),
                  ],
                ),
              ),
            )
          else ...<Widget>[
            SliverToBoxAdapter(child: feedSection()),
            SliverToBoxAdapter(child: groupsSection()),
            SliverToBoxAdapter(child: directSupportSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ],
      ),
    );
  }
}
