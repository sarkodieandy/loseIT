import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../data/models/recovery_workbook_module.dart';
import '../../../providers/accountability_providers.dart';
import '../../../providers/app_providers.dart';

class RecoveryWorkbookScreen extends ConsumerWidget {
  const RecoveryWorkbookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(userIdProvider);
    final modules = ref.watch(recoveryModulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recovery Workbook')),
      body: PremiumGate(
        lockedTitle: 'Recovery Workbook',
        lockedDescription:
            'Access interactive CBT modules, mindfulness guides, and relapse prevention strategies.',
        child: modules.when(
          data: (list) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionCard(
                child: Text(
                  'Build your recovery with guided modules covering CBT, mindfulness, motivation, and relapse prevention.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              ...list.map((module) {
                return _ModuleCard(
                  module: module,
                  userId: userId!,
                );
              }).toList(),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class _ModuleCard extends ConsumerWidget {
  final RecoveryWorkbookModule module;
  final String userId;

  const _ModuleCard({
    required this.module,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      moduleProgressProvider((userId, module.id)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(module.title),
        subtitle: Text(
          module.moduleType.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: progress.when(
          data: (p) => p != null && p.completed
              ? const Icon(Icons.check_circle, color: Colors.green)
              : null,
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(module.description),
                const SizedBox(height: 16),
                Text(
                  module.content,
                  style: const TextStyle(height: 1.6),
                ),
                const SizedBox(height: 16),
                progress.when(
                  data: (p) => FilledButton(
                    onPressed: p != null && p.completed
                        ? null
                        : () => _completeModule(context, ref),
                    child: const Text('Mark Complete'),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeModule(BuildContext context, WidgetRef ref) {
    ref.read(completeModuleProvider((userId, module.id)).future).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${module.title} completed! Well done!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error completing module: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
}
