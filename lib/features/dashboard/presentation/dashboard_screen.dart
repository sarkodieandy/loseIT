import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/data_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  List<int> get _milestones => const <int>[1, 3, 7, 14, 30, 60, 90, 180, 365];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return const _DashboardLoading();
        }

        final now = DateTime.now();
        final duration = now.difference(profile.soberStartDate);
        final safeDuration = duration.isNegative ? Duration.zero : duration;
        final days = safeDuration.inDays;
        final hours = safeDuration.inHours.remainder(24);
        final minutes = safeDuration.inMinutes.remainder(60);

        final dailySpend = profile.dailySpend ?? 0;
        final dailyMinutes = profile.dailyTimeSpent ?? 0;

        final moneySaved = dailySpend * (safeDuration.inHours / 24);
        final timeSavedHours = (dailyMinutes * days) / 60.0;

        final nextMilestone = _milestones.firstWhere(
          (m) => m > days,
          orElse: () => _milestones.last,
        );
        final progress = (days / nextMilestone).clamp(0, 1).toDouble();

        final achieved = _milestones.where((m) => m <= days).toList();
        final hitMilestone = _milestones.contains(days) && days > 0;

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
                    Text(
                      profile.displayHabitName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                    Text('Since ${Formatters.date.format(profile.soberStartDate)}'),
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
