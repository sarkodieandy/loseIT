import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class _GroupColors {
  static const Color bgTop = Color(0xFF050607);
  static const Color bgBottom = Color(0xFF0B0E11);
  static const Color card = Color(0xFF0E1216);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color muted = Color(0xFF9AA3AB);
  static const Color accent = Color(0xFF26B7FF);
  static const Color field = Color(0xFF0D1115);
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _labelController = TextEditingController(text: 'Daily 9pm check-in');
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;

    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a group.')),
      );
      return;
    }

    final title = _nameController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(challengesRepositoryProvider).createGroup(
            title: title,
            scheduleLabel: _labelController.text.trim().isEmpty
                ? null
                : _labelController.text.trim(),
          );
      ref.invalidate(challengesProvider);
      ref.invalidate(userChallengesProvider);
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _GroupColors.bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('New Group'),
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
                    _GroupColors.bgTop,
                    _GroupColors.bgBottom,
                  ],
                ),
              ),
            ),
          ),
          ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const Text(
                'Create a small accountability group. Keep it anonymous, supportive, and focused.',
                style: TextStyle(
                  color: _GroupColors.muted,
                  fontSize: 16,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _GroupColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _GroupColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Group name',
                      style: TextStyle(
                        color: _GroupColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Weekend Shield',
                        hintStyle: const TextStyle(color: _GroupColors.muted),
                        filled: true,
                        fillColor: _GroupColors.field,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Check-in label (optional)',
                      style: TextStyle(
                        color: _GroupColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _labelController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Daily 9pm check-in',
                        hintStyle: const TextStyle(color: _GroupColors.muted),
                        filled: true,
                        fillColor: _GroupColors.field,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: _GroupColors.accent,
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
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Create group'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will be joined automatically. Keep personal details out of group names.',
                style: TextStyle(
                  color: _GroupColors.muted,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

