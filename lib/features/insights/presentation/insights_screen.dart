import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/insights_engine.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/mood_log.dart';
import '../../../data/models/relapse_log.dart';
import '../../../data/models/user_habit.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/habit_selection_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final selectedHabitId = ref.watch(selectedHabitIdProvider);
    final journalAsync = ref.watch(journalControllerProvider);
    final moodAsync = ref.watch(moodLogsProvider);
    final relapseAsync = ref.watch(relapseLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Craving Rescue',
            onPressed: () => context.push('/focus'),
            icon: const Icon(Icons.self_improvement),
          ),
        ],
      ),
      body: PremiumGate(
        lockedTitle: 'Weekly Insights',
        lockedDescription: 'Upgrade to unlock risk forecasting and reports.',
        child: profileAsync.when(
          data: (profile) {
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
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

            final habitName =
                selectedHabit?.displayName ?? profile.displayHabitName;
            final habitStart =
                selectedHabit?.soberStartDate ?? profile.soberStartDate;
            final dailySpend =
                selectedHabit?.dailySpend ?? profile.dailySpend ?? 0;
            final dailyMinutes =
                selectedHabit?.dailyTimeSpent ?? profile.dailyTimeSpent ?? 0;

            final journal = (journalAsync.value ?? const <JournalEntry>[])
                .whereType<JournalEntry>()
                .toList(growable: false);
            final moods = moodAsync.asData?.value ?? const <MoodLog>[];
            final relapses =
                relapseAsync.asData?.value ?? const <RelapseLog>[];

            final now = DateTime.now();
            final report = InsightsEngine.buildWeeklyReport(
              now: now,
              journal: journal,
              moods: moods,
              relapses: relapses,
              dailySpend: dailySpend,
              dailyMinutes: dailyMinutes,
              habitId: selectedHabitId,
            );
            final risk = InsightsEngine.buildRiskForecast(
              now: now,
              soberStart: habitStart,
              journal: journal,
              moods: moods,
              relapses: relapses,
              habitId: selectedHabitId,
            );

            final hotHours = risk.hotHours.isEmpty
                ? '—'
                : risk.hotHours
                    .map((h) => '${h.toString().padLeft(2, '0')}:00')
                    .join(', ');

            return ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
              SectionCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            habitName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hot hours: $hotHours',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _RiskPill(score: risk.score, level: risk.level),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Risk Forecast',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _RiskBar(score: risk.score),
                    const SizedBox(height: 12),
                    if (risk.factors.isEmpty)
                      Text(
                        'No risk factors detected. Keep your routine steady.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else ...[
                      Text(
                        'What’s driving it',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      ...risk.factors.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $f'),
                          )),
                    ],
                    if (risk.suggestions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Next actions',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      ...risk.suggestions.map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $s'),
                          )),
                    ],
                  ],
                ),
              ),
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
                    Text(
                      '${Formatters.date.format(report.start)} → ${Formatters.date.format(report.end)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _StatChip(
                          label: 'Journal',
                          value: report.journalCount.toString(),
                        ),
                        _StatChip(
                          label: 'Moods',
                          value: report.moodCount.toString(),
                        ),
                        _StatChip(
                          label: 'Relapses',
                          value: report.relapseCount.toString(),
                        ),
                        _StatChip(
                          label: 'Saved',
                          value: Formatters.formatMoney(report.moneySaved),
                        ),
                        _StatChip(
                          label: 'Time',
                          value: '${report.timeRegainedHours.toStringAsFixed(1)}h',
                        ),
                      ],
                    ),
                    if (report.highlights.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...report.highlights.map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• $h'),
                          )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (risk.topWords.isNotEmpty)
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Common Triggers (from notes)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: risk.topWords.keys
                            .map(
                              (w) => Chip(
                                label: Text(w),
                              ),
                            )
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'These are extracted locally from your recent journal/relapse notes.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                'Tip: consistency beats intensity. If today is hard, do the smallest useful action.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 80),
            ],
          );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Failed: $error')),
        ),
      ),
    );
  }
}

class _RiskPill extends StatelessWidget {
  const _RiskPill({required this.score, required this.level});

  final int score;
  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      RiskLevel.low => ('Low', Colors.green),
      RiskLevel.medium => ('Medium', Colors.orange),
      RiskLevel.high => ('High', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label · $score',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  const _RiskBar({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final value = (score / 100).clamp(0.0, 1.0);
    final color = score >= 70
        ? Colors.red
        : score >= 40
            ? Colors.orange
            : Colors.green;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 12,
        value: value,
        color: color,
        backgroundColor: color.withValues(alpha: 0.18),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
        borderRadius: BorderRadius.circular(14),
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
