import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/app_logger.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class _ComposerColors {
  static const Color bgTop = Color(0xFF050607);
  static const Color bgBottom = Color(0xFF0B0E11);
  static const Color card = Color(0xFF0E1216);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color muted = Color(0xFF9AA3AB);
  static const Color accent = Color(0xFF26B7FF);
  static const Color chip = Color(0xFF0D1115);
}

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
      await ref
          .read(communityRepositoryProvider)
          .createPost(
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
      backgroundColor: _ComposerColors.bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('New Post'),
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
                    _ComposerColors.bgTop,
                    _ComposerColors.bgBottom,
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Text(
                'Anonymous support from people on the same path.',
                style: TextStyle(
                  color: _ComposerColors.muted,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Category',
                style: TextStyle(
                  color: _ComposerColors.muted,
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
                const Text(
                  'Label',
                  style: TextStyle(
                    color: _ComposerColors.muted,
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
                  color: _ComposerColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _ComposerColors.cardBorder),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 8,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.35,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your post…',
                    hintStyle: const TextStyle(color: _ComposerColors.muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: _ComposerColors.chip,
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
                    backgroundColor: _ComposerColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Post'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Stay anonymous. Be kind. No names, no profiles.',
                style: TextStyle(
                  color: _ComposerColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _ComposerColors.accent : _ComposerColors.chip,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : _ComposerColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : _ComposerColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
