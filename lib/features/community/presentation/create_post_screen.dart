import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  String _category = 'check_in';
  String? _badge;

  static const Map<String, List<String>> _badges = <String, List<String>>{
    'check_in': <String>[
      'Daily Pledge',
      'Morning Commitment',
      'Evening check-in',
      'Nightly Review',
    ],
    'win': <String>[
      'Milestone',
      'Urge Defeated',
      'Financial Win',
    ],
    'relapse': <String>[
      'Honest relapse',
      'Restart',
      'Venting',
      'Day 0',
    ],
    'advice': <String>[
      'Advice',
      'Need help',
    ],
  };

  @override
  void initState() {
    super.initState();
    _badge = _badges[_category]?.first;
  }

  Future<void> _submit() async {
    if (_saving) return;
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before posting.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final session = ref.read(sessionProvider);
      if (session == null) throw Exception('Not authenticated');
      final profile = ref.read(profileControllerProvider).asData?.value;
      if (profile == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete onboarding before posting.')),
        );
        context.go('/onboarding');
        return;
      }

      final now = DateTime.now();
      final topic = profile.displayHabitName;
      var streakDays = now.difference(profile.soberStartDate).inDays + 1;
      if (streakDays < 0) streakDays = 0;
      final streakLabel = _category == 'relapse' ? 'Reset' : 'Day $streakDays';
      if (_category == 'relapse') streakDays = 0;

      final alias = anonymousNameFor(session.user.id);
      await ref.read(communityRepositoryProvider).createPost(
            content: text,
            anonymousName: alias,
            category: _category,
            topic: topic,
            badge: _badge,
            streakDays: streakDays,
            streakLabel: streakLabel,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      AppLogger.error('community.createPost', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableBadges = _badges[_category] ?? const <String>[];

    return Scaffold(
      backgroundColor: TribeColors.bgTop(context),
      appBar: AppBar(
        title: const Text('New Post'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
              Text(
                'Anonymous support from people on the same path.',
                style: TextStyle(
                  color: TribeColors.muted(context),
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Category',
                style: TextStyle(
                  color: TribeColors.muted(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <_Choice>[
                  const _Choice(label: 'Check-ins', value: 'check_in'),
                  const _Choice(label: 'Wins', value: 'win'),
                  const _Choice(label: 'Relapses', value: 'relapse'),
                  const _Choice(label: 'Advice', value: 'advice'),
                ].map((choice) {
                  final selected = _category == choice.value;
                  return _ComposerPill(
                    label: choice.label,
                    selected: selected,
                    onTap: () {
                      setState(() {
                        _category = choice.value;
                        final list = _badges[_category] ?? const <String>[];
                        _badge = list.isEmpty ? null : list.first;
                      });
                    },
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 18),
              if (availableBadges.isNotEmpty) ...[
                Text(
                  'Label',
                  style: TextStyle(
                    color: TribeColors.muted(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: availableBadges.map((label) {
                    final selected = _badge == label;
                    return _ComposerPill(
                      label: label,
                      selected: selected,
                      onTap: () => setState(() => _badge = label),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 18),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TribeColors.card(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: TribeColors.cardBorder(context)),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 8,
                  style: TextStyle(
                    color: TribeColors.textPrimary(context),
                    fontSize: 16,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your post…',
                    hintStyle: TextStyle(color: TribeColors.muted(context)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: TribeColors.chip(context),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Post'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stay anonymous. Be kind. No names, no profiles.',
                style: TextStyle(
                  color: TribeColors.muted(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

class _Choice {
  const _Choice({required this.label, required this.value});

  final String label;
  final String value;
}

class _ComposerPill extends StatelessWidget {
  const _ComposerPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onSelected = Theme.of(context).colorScheme.onPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? TribeColors.accent(context)
              : TribeColors.chip(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected ? Colors.transparent : TribeColors.cardBorder(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? onSelected : TribeColors.muted(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
