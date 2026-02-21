import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/user_habit.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/habit_selection_provider.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalControllerProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final selectedHabitId = ref.watch(selectedHabitIdProvider);
    final isPremium = ref.watch(premiumControllerProvider);
    final promptsAsync = ref.watch(promptsProvider(isPremium));

    final habits = habitsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <UserHabit>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: habits.isEmpty
            ? null
            : <Widget>[
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedHabitId ?? habits.first.id,
                    items: habits
                        .map(
                          (habit) => DropdownMenuItem<String>(
                            value: habit.id,
                            child: Text(habit.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(selectedHabitIdProvider.notifier).state = value;
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'journal_fab',
        onPressed: () => context.push('/journal/new'),
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        data: (entries) {
          final filtered = selectedHabitId == null
              ? entries
              : entries
                  .where((entry) => entry.habitId == selectedHabitId)
                  .toList(growable: false);
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              if (index == 0) {
                return SectionCard(
                  child: promptsAsync.when(
                    data: (prompts) {
                      final prompt = prompts.isEmpty
                          ? null
                          : prompts[DateTime.now().day % prompts.length];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Prompt of the day',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prompt?.promptText ??
                                'What is one thing you are grateful for today?',
                          ),
                        ],
                      );
                    },
                    loading: () => const Text('Loading prompt…'),
                    error: (error, _) => Text('Failed: $error'),
                  ),
                );
              }
              if (filtered.isEmpty) {
                return const SectionCard(child: Text('No entries yet.'));
              }
              final entry = filtered[index - 1];
              return GestureDetector(
                onTap: () => context.push('/journal/${entry.id}'),
                child: SectionCard(
                  child: Row(
                    children: <Widget>[
                      if (entry.photoUrl != null) ...[
                        Hero(
                          tag: 'journal_photo_${entry.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              entry.photoUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              Formatters.date.format(entry.entryDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(entry.preview),
                            if (entry.mood != null) ...[
                              const SizedBox(height: 6),
                              Text('Mood: ${entry.mood}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: filtered.isEmpty ? 1 : filtered.length + 1,
          );
        },
        loading: () => const _JournalLoading(),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}

class _JournalLoading extends StatelessWidget {
  const _JournalLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.separated(
          itemBuilder: (context, index) => Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: 6,
        ),
      ),
    );
  }
}
