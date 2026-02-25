import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';
import 'tribe_colors.dart';

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
      await NotificationService().refreshGroupChatSubscriptions();
      if (!mounted) return;
      context.pop();
    } catch (error, stackTrace) {
      AppLogger.error('groups.create', error, stackTrace);
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
      backgroundColor: TribeColors.bgTop(context),
      appBar: AppBar(
        title: const Text('New Group'),
      ),
      body: PremiumGate(
        lockedTitle: 'Create Your Own Group',
        lockedDescription:
            'Premium lets you start a private accountability group with chat.',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'Create a small accountability group. Keep it anonymous, supportive, and focused.',
              style: TextStyle(
                color: TribeColors.muted(context),
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Group name',
                      style: TextStyle(
                        color: TribeColors.muted(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Weekend Shield',
                        hintStyle: TextStyle(color: TribeColors.muted(context)),
                        filled: true,
                        fillColor: TribeColors.field(context),
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
                    Text(
                      'Check-in label (optional)',
                      style: TextStyle(
                        color: TribeColors.muted(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _labelController,
                      decoration: InputDecoration(
                        hintText: 'Daily 9pm check-in',
                        hintStyle: TextStyle(color: TribeColors.muted(context)),
                        filled: true,
                        fillColor: TribeColors.field(context),
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
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _create,
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Text('Create group'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be joined automatically. Keep personal details out of group names.',
              style: TextStyle(
                color: TribeColors.muted(context),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
