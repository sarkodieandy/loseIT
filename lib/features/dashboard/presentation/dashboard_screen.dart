import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/user_habit.dart';
import '../../../data/models/journal_entry.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/habit_selection_provider.dart';
import '../../../providers/repository_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  List<int> get _milestones => const <int>[1, 3, 7, 14, 30, 60, 90, 180, 365];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final selectedHabitId = ref.watch(selectedHabitIdProvider);
    final isPremium = ref.watch(premiumControllerProvider);
    final promptsAsync = ref.watch(promptsProvider(isPremium));
    final journalAsync = ref.watch(journalControllerProvider);
    final milestonesAsync = ref.watch(customMilestonesProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const _DashboardLoading();
        }

        final habits = habitsAsync.maybeWhen(
          data: (items) => items,
          orElse: () => const <UserHabit>[],
        );

        UserHabit? selectedHabit;
        if (habits.isNotEmpty) {
          selectedHabit = habits.firstWhere(
            (habit) => habit.id == selectedHabitId,
            orElse: () => habits.first,
          );
        }

        final habitName = selectedHabit?.displayName ?? profile.displayHabitName;
        final habitStart = selectedHabit?.soberStartDate ?? profile.soberStartDate;
        final dailySpend = selectedHabit?.dailySpend ?? profile.dailySpend ?? 0;
        final dailyMinutes = selectedHabit?.dailyTimeSpent ?? profile.dailyTimeSpent ?? 0;

        final now = DateTime.now();
        final duration = now.difference(habitStart);
        final safeDuration = duration.isNegative ? Duration.zero : duration;
        final days = safeDuration.inDays;
        final hours = safeDuration.inHours.remainder(24);
        final minutes = safeDuration.inMinutes.remainder(60);

        final moneySaved = dailySpend * (safeDuration.inHours / 24);
        final timeSavedHours = (dailyMinutes * days) / 60.0;

        final nextMilestone = _milestones.firstWhere(
          (m) => m > days,
          orElse: () => _milestones.last,
        );
        final progress = (days / nextMilestone).clamp(0, 1).toDouble();

        final achieved = _milestones.where((m) => m <= days).toList();
        final hitMilestone = _milestones.contains(days) && days > 0;
        final journalStreak = _computeJournalStreak(
          journalAsync.value ?? const [],
          selectedHabitId,
        );
        final memory = _findOnThisDay(journalAsync.value ?? const []);
        final weeklyEntries = _countWeeklyEntries(journalAsync.value ?? const []);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: <Widget>[
              IconButton(
                onPressed: () => context.push('/relapse'),
                icon: const Icon(Icons.warning_amber),
                tooltip: 'Log relapse',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            habitName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (habits.isNotEmpty)
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedHabit?.id ?? habits.first.id,
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      child: Text(
                        '${days}d ${hours}h ${minutes}m',
                        key: ValueKey('${days}_${hours}_${minutes}'),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('Since ${Formatters.date.format(habitStart)}'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 8),
                    Text('Next milestone: $nextMilestone days'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Daily Check-in',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How are you feeling today?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        _MoodChip(label: '😊 Happy', mood: 'happy'),
                        _MoodChip(label: '😌 Calm', mood: 'calm'),
                        _MoodChip(label: '😤 Stressed', mood: 'stressed'),
                        _MoodChip(label: '😔 Sad', mood: 'sad'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: promptsAsync.when(
                  data: (prompts) {
                    final prompt = prompts.isEmpty
                        ? null
                        : prompts[DateTime.now().day % prompts.length];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Daily Motivation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          prompt?.promptText ??
                              'Keep going. Every day is a new win.',
                        ),
                      ],
                    );
                  },
                  loading: () => const Text('Loading daily motivation…'),
                  error: (error, _) => Text('Failed to load prompt: $error'),
                ),
              ),
              const SizedBox(height: 16),
              milestonesAsync.when(
                data: (milestones) {
                  if (milestones.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Custom Milestones',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...milestones.map(
                          (milestone) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '${milestone.title} '
                              '(${(milestone.currentValue ?? 0).toStringAsFixed(0)}'
                              '/${(milestone.targetValue ?? 0).toStringAsFixed(0)}'
                              '${milestone.unit ?? ''})',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Text('Milestones failed: $error'),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Row(
                  children: <Widget>[
                    const Text('🔥'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Journal streak: $journalStreak days',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              if (memory != null) ...[
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'On This Day',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(memory.preview),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Weekly Report',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Journal entries this week: $weeklyEntries'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Money Saved'),
                          const SizedBox(height: 6),
                          Text(
                            Formatters.formatMoney(moneySaved),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('Time Regained'),
                          const SizedBox(height: 6),
                          Text(
                            '${timeSavedHours.toStringAsFixed(1)}h',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recent Milestones',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 72,
                      child: achieved.isEmpty
                          ? const Center(child: Text('Your first milestone is close!'))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final milestone = achieved[index];
                                return Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text('$milestone',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      const Text('days'),
                                    ],
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemCount: achieved.length,
                            ),
                    ),
                  ],
                ),
              ),
              if (hitMilestone) ...[
                const SizedBox(height: 16),
                SectionCard(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Lottie.asset('assets/lottie/confetti.json'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You hit $days days sober. Celebrate the win!',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/journal/new'),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Add journal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/community'),
                      icon: const Icon(Icons.groups),
                      label: const Text('Community'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/challenges'),
                icon: const Icon(Icons.flag),
                label: const Text('Challenges'),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.self_improvement),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Craving Rescue',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/focus'),
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const _DashboardLoading(),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Column(
            children: <Widget>[
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodChip extends ConsumerWidget {
  const _MoodChip({
    required this.label,
    required this.mood,
  });

  final String label;
  final String mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text(label),
      onPressed: () async {
        await ref.read(moodRepositoryProvider).createLog(mood: mood);
        ref.invalidate(moodLogsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logged mood: $mood')),
          );
        }
      },
    );
  }
}

int _computeJournalStreak(List<dynamic> entries, String? habitId) {
  final byDate = <DateTime>{};
  for (final entry in entries) {
    if (entry is! JournalEntry) continue;
    if (habitId != null && entry.habitId != habitId) continue;
    final day = DateTime(entry.entryDate.year, entry.entryDate.month, entry.entryDate.day);
    byDate.add(day);
  }

  if (byDate.isEmpty) return 0;
  var streak = 0;
  var current = DateTime.now();
  var day = DateTime(current.year, current.month, current.day);
  while (byDate.contains(day)) {
    streak += 1;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

JournalEntry? _findOnThisDay(List<dynamic> entries) {
  final today = DateTime.now();
  for (final entry in entries) {
    if (entry is! JournalEntry) continue;
    if (entry.entryDate.month == today.month &&
        entry.entryDate.day == today.day &&
        entry.entryDate.year != today.year) {
      return entry;
    }
  }
  return null;
}

int _countWeeklyEntries(List<dynamic> entries) {
  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: 7));
  var count = 0;
  for (final entry in entries) {
    if (entry is! JournalEntry) continue;
    if (entry.entryDate.isAfter(cutoff)) count += 1;
  }
  return count;
}
