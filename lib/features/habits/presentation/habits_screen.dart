import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/user_habit.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/habit_selection_provider.dart';
import '../../../providers/repository_providers.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final isPremium = ref.watch(premiumControllerProvider);
    final selectedHabitId = ref.watch(selectedHabitIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your Habits')),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('No habits yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final habit = habits[index];
              return SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(habit.displayName),
                  subtitle: Text('Started ${habit.soberStartDate.toLocal()}'),
                  trailing: selectedHabitId == habit.id
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.circle_outlined),
                  onTap: () => ref
                      .read(selectedHabitIdProvider.notifier)
                      .state = habit.id,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: habits.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed: $error')),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PremiumGate(
            lockedTitle: 'Multi-habit tracking',
            lockedDescription: 'Upgrade to add more habits.',
            child: PrimaryButton(
              label: 'Add Habit',
              onPressed: () =>
                  _showAddHabitDialog(context, ref, isPremium.isPremium),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddHabitDialog(
    BuildContext context,
    WidgetRef ref,
    bool isPremium,
  ) async {
    final nameController = TextEditingController();
    DateTime startDate = DateTime.now();
    final spendController = TextEditingController();
    final timeController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Habit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Habit name'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      startDate = picked;
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Pick start date'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: spendController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily spend'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Minutes spent daily'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final habit = UserHabit(
                  id: '',
                  userId: ref.read(sessionProvider)!.user.id,
                  habitName: name,
                  habitCustomName: null,
                  soberStartDate: startDate,
                  dailySpend: double.tryParse(spendController.text),
                  dailyTimeSpent: int.tryParse(timeController.text),
                  createdAt: DateTime.now().toUtc(),
                );
                await ref.read(habitsRepositoryProvider).createHabit(habit);
                ref.invalidate(habitsProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
