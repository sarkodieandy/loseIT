import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_motion.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/animated_reveal.dart';
import '../../../data/models/challenge.dart';
import '../../../data/models/community_post.dart';
import '../../../data/models/dm_thread.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

enum _TribeTopTab { feed, groups, messages }

enum _TribeFilter {
  all(label: 'All', category: null),
  checkIns(label: 'Check-ins', category: 'check_in'),
  wins(label: 'Wins', category: 'win'),
  relapses(label: 'Relapses', category: 'relapse'),
  advice(label: 'Advice', category: 'advice');

  const _TribeFilter({required this.label, required this.category});

  final String label;
  final String? category;
}

class _TribeColors {
  static const Color bgTop = Color(0xFF050607);
  static const Color bgBottom = Color(0xFF0B0E11);
  static const Color card = Color(0xFF0E1216);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color muted = Color(0xFF9AA3AB);
  static const Color accent = Color(0xFF26B7FF);
  static const Color chip = Color(0xFF0D1115);
  static const Color green = Color(0xFF19C37D);
  static const Color red = Color(0xFFE05555);
}

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  _TribeTopTab _tab = _TribeTopTab.feed;
  _TribeFilter _filter = _TribeFilter.all;
  bool _showFab = true;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final onlineCountAsync = ref.watch(communityOnlineCountProvider);
    final onlineCount = onlineCountAsync.asData?.value;

    return Scaffold(
      backgroundColor: _TribeColors.bgTop,
      floatingActionButton: AnimatedScale(
        scale: _showFab ? 1 : 0.0,
        duration: AppMotion.fast,
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _showFab ? 1 : 0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.emphasized,
            switchOutCurve: AppMotion.exit,
            transitionBuilder: (child, animation) {
              final curved = CurvedAnimation(
                  parent: animation, curve: AppMotion.emphasized);
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
            child: switch (_tab) {
              _TribeTopTab.feed => FloatingActionButton(
                  key: const ValueKey('fab_feed'),
                  heroTag: 'tribe_post_fab',
                  backgroundColor: _TribeColors.accent,
                  foregroundColor: Colors.black,
                  onPressed: () => context.push('/community/new'),
                  child: const Icon(Icons.add),
                ),
              _TribeTopTab.groups => FloatingActionButton(
                  key: const ValueKey('fab_groups'),
                  heroTag: 'tribe_group_fab',
                  backgroundColor: _TribeColors.accent,
                  foregroundColor: Colors.black,
                  onPressed: () => context.push('/groups/new'),
                  child: const Icon(Icons.group_add_outlined),
                ),
              _TribeTopTab.messages =>
                const SizedBox.shrink(key: ValueKey('fab_none')),
            },
          ),
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
                    _TribeColors.bgTop,
                    _TribeColors.bgBottom,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse &&
                    _showFab) {
                  setState(() => _showFab = false);
                } else if (notification.direction == ScrollDirection.forward &&
                    !_showFab) {
                  setState(() => _showFab = true);
                }
                return false;
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: AnimatedReveal(
                        delay: AppMotion.stagger(0),
                        child: _TribeHeader(
                          onlineCount: onlineCount,
                          onSearch: () => _showSearch(context),
                          onFilters: () => _showFilters(context),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: AnimatedReveal(
                        delay: AppMotion.stagger(1),
                        child: _TribeTopTabs(
                          selected: _tab,
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _tab = value;
                              _showFab = true;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  if (_tab == _TribeTopTab.feed) ..._buildFeedSlivers(session),
                  if (_tab == _TribeTopTab.groups) ..._buildGroupsSlivers(),
                  if (_tab == _TribeTopTab.messages)
                    ..._buildMessagesSlivers(session),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeedSlivers(Session? session) {
    final feedAsync = ref.watch(communityFeedProvider(_filter.category));
    final challengesAsync = ref.watch(challengesProvider);
    final connectionsAsync = ref.watch(supportConnectionsProvider);

    final headerTitle = switch (_filter) {
      _TribeFilter.all => 'Today in your circle',
      _TribeFilter.checkIns => 'Latest Check-ins',
      _TribeFilter.wins => 'Recent Wins',
      _TribeFilter.relapses => 'Recent Shares',
      _TribeFilter.advice => 'Advice Requests',
    };

    final headerRight = switch (_filter) {
      _TribeFilter.all => 'View all',
      _ => null,
    };

    final postsValue = feedAsync.asData?.value ?? const <CommunityPost>[];
    final todayWins = _filter == _TribeFilter.wins
        ? postsValue
            .where(
              (p) =>
                  (p.category ?? '').toLowerCase() == 'win' &&
                  _isToday(p.createdAt),
            )
            .length
        : null;

    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: AnimatedReveal(
            key: ValueKey('tribe_filters_${_filter.name}'),
            delay: AppMotion.stagger(2),
            duration: AppMotion.medium,
            child: _TribeFilters(
              selected: _filter,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _filter = value);
              },
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                headerTitle,
                style: const TextStyle(
                  color: _TribeColors.muted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (headerRight != null)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _TribeColors.accent,
                  ),
                  child: Text(headerRight),
                ),
            ],
          ),
        ),
      ),
      if (todayWins != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: AnimatedReveal(
              key: ValueKey('tribe_wins_$todayWins'),
              delay: AppMotion.stagger(3),
              duration: AppMotion.medium,
              child: _TribeHighlightCard(
                title: '${todayWins.toString()} Wins Today',
                subtitle: 'The community is staying strong.',
                icon: Icons.emoji_events_outlined,
              ),
            ),
          ),
        ),
      feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Text(
                  'No posts yet. Be the first.',
                  style: TextStyle(color: _TribeColors.muted),
                ),
              ),
            );
          }

          final count = posts.length.clamp(0, 50).toInt();

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final post = posts[index];
                return AnimatedReveal(
                  key: ValueKey('post_${post.id}'),
                  delay: AppMotion.stagger(index, stepMs: 38, maxSteps: 8),
                  duration: AppMotion.medium,
                  child: _TribePostCard(
                    post: post,
                    isSelf: session?.user.id == post.userId,
                    onOpenThread: () => context.push('/community/${post.id}'),
                    onLike: () async {
                      await ref
                          .read(communityRepositoryProvider)
                          .likePost(post.id, post.likes);
                    },
                    onSendSupport: () {
                      if (session?.user.id == post.userId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You cannot message yourself.'),
                          ),
                        );
                        return;
                      }
                      context.push(
                        '/dm/user/${post.userId}',
                        extra: post.anonymousName,
                      );
                    },
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemCount: count,
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, _) => SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _friendlyBackendError(error),
              style: const TextStyle(color: _TribeColors.muted),
            ),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _SectionHeader(
            title: 'Accountability groups',
            action: 'Explore',
            onTap: () => context.push('/challenges'),
          ),
        ),
      ),
      challengesAsync.when(
        data: (challenges) {
          if (challenges.isEmpty) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          final count = challenges.length.clamp(0, 8).toInt();

          return SliverToBoxAdapter(
            child: SizedBox(
              height: 146,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => AnimatedReveal(
                  key: ValueKey('group_card_${challenges[index].id}'),
                  delay: AppMotion.stagger(index, stepMs: 38, maxSteps: 8),
                  duration: AppMotion.medium,
                  beginOffset: const Offset(0.10, 0),
                  child: _TribeGroupCard(
                    challenge: challenges[index],
                    onTap: () =>
                        context.push('/groups/${challenges[index].id}'),
                  ),
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: count,
              ),
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(
          child: SizedBox(
            height: 146,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _SectionHeader(
            title: 'Direct support',
            action: 'Open',
            onTap: () => context.push('/support'),
          ),
        ),
      ),
      connectionsAsync.when(
        data: (connections) {
          final active = connections.where((c) => c.isActive).toList();
          if (active.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AnimatedReveal(
                  delay: AppMotion.stagger(2),
                  child: _TribeSupportCard(
                    title: 'Add a support buddy',
                    subtitle: 'Invite someone you trust to message you here.',
                    onTap: () => context.push('/support'),
                  ),
                ),
              ),
            );
          }
          final first = active.first;
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AnimatedReveal(
                delay: AppMotion.stagger(2),
                child: _TribeSupportCard(
                  title: first.contactName ?? 'Support session',
                  subtitle: (first.relationship?.trim().isEmpty ?? true)
                      ? 'Leave a note'
                      : first.relationship!,
                  onTap: () => context.push('/support/${first.id}'),
                ),
              ),
            ),
          );
        },
        loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
        error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      ),
    ];
  }

  List<Widget> _buildGroupsSlivers() {
    final challengesAsync = ref.watch(challengesProvider);
    final userChallengesAsync = ref.watch(userChallengesProvider);

    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: AnimatedReveal(
            delay: AppMotion.stagger(2),
            duration: AppMotion.medium,
            child: _SectionHeader(
              title: 'Groups',
              action: 'See all',
              onTap: () => context.push('/challenges'),
            ),
          ),
        ),
      ),
      challengesAsync.when(
        data: (challenges) {
          if (challenges.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No groups yet.',
                  style: TextStyle(color: _TribeColors.muted),
                ),
              ),
            );
          }

          final joined = userChallengesAsync.asData?.value ?? const [];

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final isJoined =
                    joined.any((item) => item.challengeId == challenge.id);
                return AnimatedReveal(
                  key: ValueKey('group_row_${challenge.id}'),
                  delay: AppMotion.stagger(index, stepMs: 32, maxSteps: 8),
                  duration: AppMotion.medium,
                  child: _TribeGroupRow(
                    challenge: challenge,
                    joined: isJoined,
                    onTap: () => context.push('/groups/${challenge.id}'),
                    onJoin: () async {
                      if (isJoined) {
                        context.push('/groups/${challenge.id}');
                        return;
                      }
                      await ref
                          .read(challengesRepositoryProvider)
                          .startChallenge(challenge.id);
                      ref.invalidate(userChallengesProvider);
                      ref.invalidate(challengesProvider);
                    },
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: challenges.length.clamp(0, 30).toInt(),
            ),
          );
        },
        loading: () => const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              _friendlyBackendError(error),
              style: const TextStyle(color: _TribeColors.muted),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMessagesSlivers(Session? session) {
    final threadsAsync = ref.watch(dmThreadsProvider);
    if (session == null) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'Sign in to use messages.',
              style: TextStyle(color: _TribeColors.muted),
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: AnimatedReveal(
            delay: AppMotion.stagger(2),
            duration: AppMotion.medium,
            child: _SectionHeader(
              title: 'Messages',
              action: 'Inbox',
              onTap: () => context.push('/dm'),
            ),
          ),
        ),
      ),
      threadsAsync.when(
        data: (threads) {
          if (threads.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No messages yet.',
                  style: TextStyle(color: _TribeColors.muted),
                ),
              ),
            );
          }
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final thread = threads[index];
                return AnimatedReveal(
                  key: ValueKey('thread_${thread.id}'),
                  delay: AppMotion.stagger(index, stepMs: 30, maxSteps: 10),
                  duration: AppMotion.medium,
                  child: _TribeThreadRow(
                    thread: thread,
                    myUserId: session.user.id,
                    onTap: (otherAlias) => context.push(
                      '/dm/thread/${thread.id}',
                      extra: otherAlias,
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: threads.length.clamp(0, 50).toInt(),
            ),
          );
        },
        loading: () => const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              _friendlyBackendError(error),
              style: const TextStyle(color: _TribeColors.muted),
            ),
          ),
        ),
      ),
    ];
  }

  String _friendlyBackendError(Object error) {
    final message = error.toString();
    if (message.contains('relation \"public.dm_threads\"') ||
        message.contains('dm_threads')) {
      return 'Messages backend is not set up yet.\n\n'
          'Run `supabase/schema.sql` in Supabase SQL Editor to create `dm_threads` and `dm_messages`.';
    }
    if (message.contains('relation \"public.challenges\"') ||
        message.contains('relation \"public.user_challenges\"') ||
        message.contains('challenges')) {
      return 'Groups backend is not set up yet.\n\n'
          'Run `supabase/schema.sql` in Supabase SQL Editor to create `challenges` and `user_challenges`.';
    }
    if (message.contains('relation \"public.community_posts\"') ||
        message.contains('relation \"public.community_replies\"')) {
      return 'Community backend is not set up yet.\n\n'
          'Run `supabase/schema.sql` in Supabase SQL Editor to create community tables.';
    }
    if (message.contains('violates row-level security policy') ||
        message.contains('permission denied')) {
      return 'Permission blocked by RLS.\n\n'
          'Make sure you are signed in, and run `supabase/schema.sql` to install RLS policies.';
    }
    return 'Failed: $message';
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _TribeColors.card,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search posts…',
                hintStyle: const TextStyle(color: _TribeColors.muted),
                filled: true,
                fillColor: _TribeColors.chip,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _TribeColors.card,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Filters',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the chips on the main screen to filter by category.',
              style: TextStyle(color: _TribeColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _TribeHeader extends StatelessWidget {
  const _TribeHeader({
    required this.onlineCount,
    required this.onSearch,
    required this.onFilters,
  });

  final int? onlineCount;
  final VoidCallback onSearch;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text(
              'Community',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 12),
            _Pill(
              icon: Icons.shield_outlined,
              label: 'Anon, safe space',
            ),
            const Spacer(),
            _IconCircleButton(
              icon: Icons.search,
              onPressed: onSearch,
            ),
            const SizedBox(width: 10),
            _IconCircleButton(
              icon: Icons.filter_alt_outlined,
              onPressed: onFilters,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Expanded(
              child: Text(
                'Real people, same battle. No names, no profiles.',
                style: TextStyle(
                  color: _TribeColors.muted,
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (onlineCount != null)
              _OnlineNow(count: onlineCount!)
            else
              const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }
}

class _OnlineNow extends StatelessWidget {
  const _OnlineNow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const _PulseDot(color: _TribeColors.green),
        const SizedBox(width: 8),
        Text(
          '$count online\nnow',
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: _TribeColors.muted,
            fontSize: 13,
            height: 1.15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anim =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 0).animate(anim),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 2.6).animate(anim),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
            child: const SizedBox(width: 10, height: 10),
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: _TribeColors.cardBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TribeColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: _TribeColors.muted),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _TribeColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TribeTopTabs extends StatelessWidget {
  const _TribeTopTabs({
    required this.selected,
    required this.onChanged,
  });

  final _TribeTopTab selected;
  final ValueChanged<_TribeTopTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TribeColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          _TabItem(
            label: 'Feed',
            selected: selected == _TribeTopTab.feed,
            onTap: () => onChanged(_TribeTopTab.feed),
          ),
          _TabItem(
            label: 'Groups',
            selected: selected == _TribeTopTab.groups,
            onTap: () => onChanged(_TribeTopTab.groups),
          ),
          _TabItem(
            label: 'Messages',
            selected: selected == _TribeTopTab.messages,
            onTap: () => onChanged(_TribeTopTab.messages),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedScale(
        scale: selected ? 1 : 0.985,
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : _TribeColors.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TribeFilters extends StatelessWidget {
  const _TribeFilters({
    required this.selected,
    required this.onChanged,
  });

  final _TribeFilter selected;
  final ValueChanged<_TribeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Filters',
          style: TextStyle(
            color: _TribeColors.muted,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _TribeFilter.values.map((filter) {
            final isSelected = filter == selected;
            return _ChoicePill(
              label: filter.label,
              selected: isSelected,
              onTap: () => onChanged(filter),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1 : 0.985,
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _TribeColors.accent : _TribeColors.chip,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.transparent : _TribeColors.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : _TribeColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: _TribeColors.muted,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: _TribeColors.accent),
          child: Text(action),
        ),
      ],
    );
  }
}

class _TribePostCard extends StatelessWidget {
  const _TribePostCard({
    required this.post,
    required this.isSelf,
    required this.onOpenThread,
    required this.onLike,
    required this.onSendSupport,
  });

  final CommunityPost post;
  final bool isSelf;
  final VoidCallback onOpenThread;
  final VoidCallback onLike;
  final VoidCallback onSendSupport;

  @override
  Widget build(BuildContext context) {
    final timeAgo = Formatters.timeAgo(post.createdAt);
    final topic = (post.topic?.trim().isNotEmpty ?? false)
        ? post.topic!.trim()
        : 'General';
    final streak = _streakText(post);
    final header = streak.isEmpty ? 'Anon' : 'Anon • $streak';
    final badge =
        (post.badge?.trim().isNotEmpty ?? false) ? post.badge!.trim() : null;
    final cta = _ctaText(post);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _TribeColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _TribeColors.cardBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Avatar(seed: post.userId),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      header,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$topic · $timeAgo',
                      style: const TextStyle(
                        color: _TribeColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) _BadgePill(label: badge, post: post),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _MetaIcon(
                icon: Icons.favorite_border,
                label: post.likes.toString(),
                onTap: onLike,
              ),
              const SizedBox(width: 14),
              _MetaIcon(
                icon: Icons.chat_bubble_outline,
                label: post.replyCount.toString(),
                onTap: onOpenThread,
              ),
              const Spacer(),
              TextButton(
                onPressed: isSelf ? null : onSendSupport,
                style: TextButton.styleFrom(
                  foregroundColor: _TribeColors.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                child: Row(
                  children: <Widget>[
                    Text(
                      cta,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_outward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _ctaText(CommunityPost post) {
    switch ((post.category ?? '').toLowerCase()) {
      case 'win':
        return 'Congratulate';
      case 'relapse':
        return 'Send strength';
      case 'advice':
        return 'Share advice';
      case 'check_in':
      default:
        return 'Send support';
    }
  }

  String _streakText(CommunityPost post) {
    final category = (post.category ?? '').toLowerCase();
    if (category == 'relapse') {
      return (post.streakLabel?.trim().isNotEmpty ?? false)
          ? post.streakLabel!.trim()
          : 'Reset';
    }
    if (post.streakDays != null) {
      final days = post.streakDays!;
      if (days <= 0) return 'Day 0';
      if (days == 1) return 'Day 1';
      return '$days days';
    }
    if (post.streakLabel != null && post.streakLabel!.trim().isNotEmpty) {
      return post.streakLabel!.trim();
    }
    return '';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.seed});

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

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.post});

  final String label;
  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    final category = (post.category ?? '').toLowerCase();
    final bg = switch (category) {
      'win' => _TribeColors.green.withValues(alpha: 0.25),
      'relapse' => _TribeColors.red.withValues(alpha: 0.25),
      _ => _TribeColors.green.withValues(alpha: 0.18),
    };

    final fg = switch (category) {
      'win' => _TribeColors.green,
      'relapse' => _TribeColors.red,
      _ => const Color(0xFF90E2C3),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MetaIcon extends StatelessWidget {
  const _MetaIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(icon, color: _TribeColors.muted, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _TribeColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TribeGroupCard extends StatelessWidget {
  const _TribeGroupCard({
    required this.challenge,
    required this.onTap,
  });

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xFF0C2A2B),
              const Color(0xFF0E141A),
            ],
          ),
          border: Border.all(color: _TribeColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              challenge.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Small group · ${challenge.memberCount} members',
              style: const TextStyle(
                color: _TribeColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (challenge.description != null &&
                challenge.description!.trim().isNotEmpty)
              _SmallPill(
                label: challenge.description!,
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _TribeColors.cardBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _TribeSupportCard extends StatelessWidget {
  const _TribeSupportCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _TribeColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _TribeColors.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            const _Avatar(seed: 'support'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _TribeColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _TribeColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TribeThreadRow extends StatelessWidget {
  const _TribeThreadRow({
    required this.thread,
    required this.myUserId,
    required this.onTap,
  });

  final DmThread thread;
  final String myUserId;
  final void Function(String otherAlias) onTap;

  @override
  Widget build(BuildContext context) {
    final otherUserId = thread.userA == myUserId ? thread.userB : thread.userA;
    final alias =
        'Anon#${otherUserId.replaceAll('-', '').toUpperCase().substring(0, 4)}';
    final last = Formatters.timeAgo(thread.lastMessageAt);

    return InkWell(
      onTap: () => onTap(alias),
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _TribeColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _TribeColors.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            _Avatar(seed: otherUserId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alias,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last activity $last',
                    style: const TextStyle(
                      color: _TribeColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _TribeColors.muted),
          ],
        ),
      ),
    );
  }
}

class _TribeGroupRow extends StatelessWidget {
  const _TribeGroupRow({
    required this.challenge,
    required this.joined,
    required this.onTap,
    required this.onJoin,
  });

  final Challenge challenge;
  final bool joined;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _TribeColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _TribeColors.cardBorder),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.shield_outlined, color: _TribeColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${challenge.memberCount} members',
                    style: const TextStyle(
                      color: _TribeColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: onJoin,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    joined ? _TribeColors.muted : _TribeColors.accent,
                side: BorderSide(
                  color: joined ? _TribeColors.cardBorder : _TribeColors.accent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(joined ? 'Open' : 'Join'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TribeHighlightCard extends StatelessWidget {
  const _TribeHighlightCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            Color(0xFF0C2A2B),
            Color(0xFF0E141A),
          ],
        ),
        border: Border.all(color: _TribeColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0F7F5A),
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _TribeColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isToday(DateTime value) {
  final now = DateTime.now();
  return value.year == now.year &&
      value.month == now.month &&
      value.day == now.day;
}
