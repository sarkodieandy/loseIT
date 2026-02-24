import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/custom_milestone.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class MilestonesScreen extends ConsumerWidget {
  /// optional id passed via deep link/query parameters to highlight
  final String? initialAchievementId;

  const MilestonesScreen({super.key, this.initialAchievementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(customMilestonesProvider);
    final isPremium = ref.watch(premiumControllerProvider);

    // if a deep link brought us here with an achievement id, show a simple
    // snack bar notification so the user knows why they were redirected.
    if (initialAchievementId != null && milestonesAsync is AsyncData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New achievement unlocked!'),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Milestones')),
      body: PremiumGate(
        lockedTitle: 'Custom Milestones',
        lockedDescription:
            'Upgrade to create personal goals and progress rings.',
        child: milestonesAsync.when(
          data: (milestones) {
            if (milestones.isEmpty) {
              return const Center(child: Text('No milestones yet.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemBuilder: (context, index) {
                final milestone = milestones[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        milestone.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${(milestone.currentValue ?? 0).toStringAsFixed(0)}'
                        '/${(milestone.targetValue ?? 0).toStringAsFixed(0)}'
                        '${milestone.unit ?? ''}',
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: milestones.length,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed: $error')),
        ),
      ),
      floatingActionButton: isPremium.isPremium
          ? FloatingActionButton(
              heroTag: 'milestones_add',
              onPressed: () => _showAddDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final unitController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target value'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit (optional)'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              final milestone = CustomMilestone(
                id: '',
                userId: '',
                title: title,
                targetValue: double.tryParse(targetController.text),
                currentValue: 0,
                unit: unitController.text.trim().isEmpty
                    ? null
                    : unitController.text.trim(),
                createdAt: DateTime.now().toUtc(),
              );
              await ref
                  .read(milestonesRepositoryProvider)
                  .createMilestone(milestone);
              ref.invalidate(customMilestonesProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
