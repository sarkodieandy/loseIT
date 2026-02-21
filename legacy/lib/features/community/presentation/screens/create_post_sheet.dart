import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../services/supabase/supabase_error_text.dart';
import '../../model/community_models.dart';

class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({
    super.key,
    required this.initialStreakDays,
  });

  final int initialStreakDays;

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _messageController = TextEditingController();
  final _topicController = TextEditingController();
  final _customBadgeController = TextEditingController();

  CommunityPostKind _kind = CommunityPostKind.advice;
  bool _useCustomBadge = false;
  String _selectedBadge = '';
  bool _relapseReset = true;
  bool _showTopicField = false;
  bool _hasMessage = false;
  bool _busy = false;
  String? _error;

  bool _didInitFromDependencies = false;

  @override
  void initState() {
    super.initState();
    _syncDefaultBadge(force: true);
    _messageController.addListener(_onMessageChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromDependencies) return;
    _didInitFromDependencies = true;

    final app = AppScope.of(context);
    final defaultTopic = app.state.onboardingProfile.addictionLabel.trim();
    if (_topicController.text.trim().isEmpty &&
        defaultTopic.isNotEmpty &&
        defaultTopic != 'Discipline') {
      _topicController.text = defaultTopic;
    }
  }

  void _onMessageChanged() {
    final nextHasMessage = _messageController.text.trim().isNotEmpty;
    if (nextHasMessage == _hasMessage) return;
    setState(() => _hasMessage = nextHasMessage);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _topicController.dispose();
    _customBadgeController.dispose();
    super.dispose();
  }

  int get _streakDaysForPost {
    if (_kind == CommunityPostKind.relapse && _relapseReset) return 0;
    return widget.initialStreakDays;
  }

  String get _placeholder {
    return switch (_kind) {
      CommunityPostKind.advice => 'Ask for advice or share context…',
      CommunityPostKind.checkIn => 'Share a quick check-in…',
      CommunityPostKind.win => 'Share a win (big or small)…',
      CommunityPostKind.relapse => 'Share what happened and what you need…',
    };
  }

  List<String> _badgeSuggestions() {
    return switch (_kind) {
      CommunityPostKind.advice => const <String>['Advice'],
      CommunityPostKind.checkIn =>
        const <String>['Daily Pledge', 'Morning Commitment', 'Nightly Review'],
      CommunityPostKind.win =>
        const <String>['Milestone', 'Urge Defeated', 'Financial Win'],
      CommunityPostKind.relapse => _relapseReset
          ? const <String>['Day 0', 'Restart', 'Venting']
          : <String>[
              if (widget.initialStreakDays > 0)
                '${widget.initialStreakDays} Day Streak',
              'Restart',
              'Venting',
            ],
    };
  }

  void _syncDefaultBadge({bool force = false}) {
    if (_useCustomBadge) return;
    final suggestions = _badgeSuggestions();
    if (suggestions.isEmpty) {
      _selectedBadge = '';
      return;
    }
    if (force || _selectedBadge.trim().isEmpty || !suggestions.contains(_selectedBadge)) {
      _selectedBadge = suggestions.first;
    }
  }

  void _setKind(CommunityPostKind kind) {
    if (_kind == kind) return;
    setState(() {
      _kind = kind;
      _error = null;
      if (_kind != CommunityPostKind.relapse) {
        _relapseReset = true;
      }
      _useCustomBadge = false;
      _customBadgeController.clear();
      _syncDefaultBadge(force: true);
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final app = AppScope.of(context);
    try {
      _syncDefaultBadge();
      final badgeText = _useCustomBadge
          ? _customBadgeController.text.trim()
          : _selectedBadge.trim();
      final topicText = _topicController.text.trim();

      final created = await app.services.community.createPost(
        kind: _kind,
        message: message,
        streakDays: _streakDaysForPost,
        topic: topicText.isEmpty ? null : topicText,
        label: badgeText.isEmpty ? null : badgeText,
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error, stackTrace) {
      AppLogger.error('CreatePostSheet.submit', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _error = supabaseErrorText(error);
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final maxHeight =
        (media.size.height * 0.82).clamp(360.0, media.size.height);

    final canPost = !_busy && _hasMessage;

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

    final badgeSuggestions = _badgeSuggestions();
    final topicLabel = _topicController.text.trim();

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: DisciplineColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
                border: Border.all(
                  color: DisciplineColors.border.withValues(alpha: 0.75),
                ),
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: DisciplineColors.border.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'New post',
                          style: DisciplineTextStyles.section,
                        ),
                        Row(
                          children: <Widget>[
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: canPost ? _submit : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: DisciplineColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: DisciplineColors.accent
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                child: Text(
                                  _busy ? 'Posting…' : 'Post',
                                  style: DisciplineTextStyles.caption.copyWith(
                                    color: DisciplineColors.background,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 18,
                                color: DisciplineColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Alias only. Keep it focused and supportive.',
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.textTertiary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () =>
                              setState(() => _showTopicField = !_showTopicField),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                CupertinoIcons.tag,
                                size: 14,
                                color: DisciplineColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 110),
                                child: Text(
                                  topicLabel.isEmpty ? 'Topic' : topicLabel,
                                  overflow: TextOverflow.ellipsis,
                                  style: DisciplineTextStyles.caption.copyWith(
                                    color: DisciplineColors.accent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (_showTopicField) ...[
                      const SizedBox(height: 10),
                      CupertinoTextField(
                        controller: _topicController,
                        placeholder: 'Topic (optional)',
                        style: DisciplineTextStyles.body,
                        placeholderStyle: DisciplineTextStyles.secondary,
                        cursorColor: DisciplineColors.accent,
                        decoration: BoxDecoration(
                          color: DisciplineColors.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                DisciplineColors.border.withValues(alpha: 0.7),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Type', style: DisciplineTextStyles.caption),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          pill(
                            label: 'Advice',
                            selected: _kind == CommunityPostKind.advice,
                            onPressed: () => _setKind(CommunityPostKind.advice),
                          ),
                          const SizedBox(width: 10),
                          pill(
                            label: 'Check-in',
                            selected: _kind == CommunityPostKind.checkIn,
                            onPressed: () => _setKind(CommunityPostKind.checkIn),
                          ),
                          const SizedBox(width: 10),
                          pill(
                            label: 'Win',
                            selected: _kind == CommunityPostKind.win,
                            onPressed: () => _setKind(CommunityPostKind.win),
                          ),
                          const SizedBox(width: 10),
                          pill(
                            label: 'Relapse',
                            selected: _kind == CommunityPostKind.relapse,
                            onPressed: () => _setKind(CommunityPostKind.relapse),
                          ),
                        ],
                      ),
                    ),
                    if (_kind == CommunityPostKind.relapse) ...[
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            pill(
                              label: 'Reset (Day 0)',
                              selected: _relapseReset,
                              onPressed: () {
                                setState(() {
                                  _relapseReset = true;
                                  _useCustomBadge = false;
                                  _customBadgeController.clear();
                                  _syncDefaultBadge(force: true);
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            pill(
                              label: 'Streak lost',
                              selected: !_relapseReset,
                              onPressed: () {
                                setState(() {
                                  _relapseReset = false;
                                  _useCustomBadge = false;
                                  _customBadgeController.clear();
                                  _syncDefaultBadge(force: true);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text('Badge', style: DisciplineTextStyles.caption),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          ...badgeSuggestions.map((badge) {
                            final selected =
                                !_useCustomBadge && _selectedBadge == badge;
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: pill(
                                label: badge,
                                selected: selected,
                                onPressed: () {
                                  setState(() {
                                    _useCustomBadge = false;
                                    _selectedBadge = badge;
                                  });
                                },
                              ),
                            );
                          }),
                          pill(
                            label: 'Custom',
                            selected: _useCustomBadge,
                            onPressed: () {
                              setState(() {
                                _useCustomBadge = true;
                                _customBadgeController.text = _selectedBadge;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_useCustomBadge) ...[
                      const SizedBox(height: 10),
                      CupertinoTextField(
                        controller: _customBadgeController,
                        placeholder: 'Custom badge',
                        style: DisciplineTextStyles.body,
                        placeholderStyle: DisciplineTextStyles.secondary,
                        cursorColor: DisciplineColors.accent,
                        decoration: BoxDecoration(
                          color: DisciplineColors.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                DisciplineColors.border.withValues(alpha: 0.7),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        clearButtonMode: OverlayVisibilityMode.editing,
                      ),
                    ],
                    const SizedBox(height: 10),
                    CupertinoTextField(
                      controller: _messageController,
                      placeholder: _placeholder,
                      style: DisciplineTextStyles.body,
                      placeholderStyle: DisciplineTextStyles.secondary,
                      cursorColor: DisciplineColors.accent,
                      decoration: BoxDecoration(
                        color: DisciplineColors.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DisciplineColors.border.withValues(alpha: 0.7),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      minLines: 3,
                      maxLines: 7,
                      textInputAction: TextInputAction.newline,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.danger,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
