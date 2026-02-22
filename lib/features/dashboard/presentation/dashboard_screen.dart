import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/app_motion.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/insights_engine.dart';
import '../../../core/widgets/animated_reveal.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/user_habit.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/mood_log.dart';
import '../../../data/models/relapse_log.dart';
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
    final moodsAsync = ref.watch(moodLogsProvider);
    final relapsesAsync = ref.watch(relapseLogsProvider);

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

        final journalEntries = journalAsync.value ?? const <JournalEntry>[];
        final moodLogs = moodsAsync.asData?.value ?? const <MoodLog>[];
        final relapseLogs = relapsesAsync.asData?.value ?? const <RelapseLog>[];
        final weeklyReport = InsightsEngine.buildWeeklyReport(
          now: now,
          journal: journalEntries,
          moods: moodLogs,
          relapses: relapseLogs,
          dailySpend: dailySpend,
          dailyMinutes: dailyMinutes,
          habitId: selectedHabitId,
        );
        final risk = InsightsEngine.buildRiskForecast(
          now: now,
          soberStart: habitStart,
          journal: journalEntries,
          moods: moodLogs,
          relapses: relapseLogs,
          habitId: selectedHabitId,
        );

        var revealIndex = 0;
        Widget reveal(Widget child) => AnimatedReveal(
              delay: AppMotion.stagger(revealIndex++),
              child: child,
            );

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Dashboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            actions: <Widget>[
              IconButton(
                onPressed: () => context.push('/relapse'),
                icon: const Icon(Icons.warning_amber),
                tooltip: 'Log relapse',
              ),
            ],
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
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                        Theme.of(context).scaffoldBackgroundColor,
                        Theme.of(context).colorScheme.secondary.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: <Widget>[
                    reveal(
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
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.14),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
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
                                          fontWeight: FontWeight.w700,
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
                                          ref.read(selectedHabitIdProvider.notifier).state =
                                              value;
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: AppMotion.slow,
                              switchInCurve: AppMotion.emphasized,
                              switchOutCurve: AppMotion.exit,
                              transitionBuilder: (child, animation) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: AppMotion.emphasized,
                                );
                                return FadeTransition(
                                  opacity: curved,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.12),
                                      end: Offset.zero,
                                    ).animate(curved),
                                    child: ScaleTransition(
                                      scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
                                      child: child,
                                    ),
                                  ),
                                );
                              },
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
                            _SmoothLinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                              duration: AppMotion.slow,
                              curve: AppMotion.emphasized,
                            ),
                            const SizedBox(height: 8),
                            Text('Next milestone: $nextMilestone days'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    reveal(
                      const SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Daily Check-in',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: 8),
                            Text('How are you feeling today?'),
                            SizedBox(height: 12),
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
                    ),
                    const SizedBox(height: 16),
                    reveal(
                      SectionCard(
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Risk forecast',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    switch (risk.level) {
                                      RiskLevel.low =>
                                        'Low risk right now. Keep your routine steady.',
                                      RiskLevel.medium =>
                                        'Medium risk. Stay intentional for the next few hours.',
                                      RiskLevel.high =>
                                        'High risk window. Keep support close and reduce triggers.',
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  _SmoothLinearProgressIndicator(
                                    value: (risk.score / 100).clamp(0.0, 1.0),
                                    minHeight: 10,
                                    borderRadius: BorderRadius.circular(999),
                                    duration: AppMotion.slow,
                                    curve: AppMotion.emphasized,
                                    color: risk.level == RiskLevel.high
                                        ? Colors.red
                                        : risk.level == RiskLevel.medium
                                            ? Colors.orange
                                            : Colors.green,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => context.push('/insights'),
                              child: const Text('Details'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    reveal(
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
                    ),
                    const SizedBox(height: 16),
                    milestonesAsync.when(
                      data: (milestones) {
                        if (milestones.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return reveal(
                          SectionCard(
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
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (error, _) => Text('Milestones failed: $error'),
                    ),
                    const SizedBox(height: 16),
                    reveal(
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
                    ),
                    if (memory != null) ...[
                      const SizedBox(height: 16),
                      reveal(
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
                      ),
                    ],
                    const SizedBox(height: 16),
                    reveal(
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Weekly Report',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                _MiniStat(
                                  label: 'Journal',
                                  value: weeklyReport.journalCount.toString(),
                                ),
                                _MiniStat(
                                  label: 'Moods',
                                  value: weeklyReport.moodCount.toString(),
                                ),
                                _MiniStat(
                                  label: 'Relapses',
                                  value: weeklyReport.relapseCount.toString(),
                                ),
                                _MiniStat(
                                  label: 'Saved',
                                  value: Formatters.formatMoney(weeklyReport.moneySaved),
                                ),
                              ],
                            ),
                            if (weeklyReport.highlights.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                weeklyReport.highlights.first,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => context.push('/insights'),
                                child: const Text('View insights'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    reveal(
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
                    ),
                    const SizedBox(height: 16),
                    reveal(
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
                                  ? const Center(
                                      child: Text('Your first milestone is close!'),
                                    )
                                  : ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        final milestone = achieved[index];
                                        return AnimatedReveal(
                                          key: ValueKey('mile_$milestone'),
                                          delay: AppMotion.stagger(index, stepMs: 35, maxSteps: 8),
                                          duration: AppMotion.medium,
                                          beginOffset: const Offset(0.08, 0),
                                          child: Container(
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
                                                Text(
                                                  '$milestone',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(fontWeight: FontWeight.bold),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text('days'),
                                              ],
                                            ),
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
                    ),
                    if (hitMilestone) ...[
                      const SizedBox(height: 16),
                      reveal(
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
                      ),
                    ],
                    const SizedBox(height: 20),
                    reveal(
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
                    ),
                    const SizedBox(height: 12),
                    reveal(
                      OutlinedButton.icon(
                        onPressed: () => context.push('/challenges'),
                        icon: const Icon(Icons.flag),
                        label: const Text('Challenges'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    reveal(
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

class _SmoothLinearProgressIndicator extends StatefulWidget {
  const _SmoothLinearProgressIndicator({
    required this.value,
    required this.minHeight,
    required this.borderRadius,
    this.duration = AppMotion.medium,
    this.curve = AppMotion.standard,
    this.color,
    this.backgroundColor,
  });

  final double value;
  final double minHeight;
  final BorderRadius borderRadius;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<_SmoothLinearProgressIndicator> createState() =>
      _SmoothLinearProgressIndicatorState();
}

class _SmoothLinearProgressIndicatorState
    extends State<_SmoothLinearProgressIndicator> {
  double _previous = 0;

  @override
  void didUpdateWidget(covariant _SmoothLinearProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previous = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: _previous, end: target),
        duration: widget.duration,
        curve: widget.curve,
        builder: (context, value, child) => LinearProgressIndicator(
          value: value,
          minHeight: widget.minHeight,
          color: widget.color,
          backgroundColor: widget.backgroundColor,
        ),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$label ',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
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
