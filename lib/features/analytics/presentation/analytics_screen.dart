import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/services/health_service.dart';
import '../../../providers/app_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          PremiumGate(
            lockedTitle: 'Analytics',
            lockedDescription: 'Upgrade to unlock deep insights and charts.',
            child: Column(
              children: <Widget>[
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Money Saved',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: <LineChartBarData>[
                              LineChartBarData(
                                color: Theme.of(context).colorScheme.primary,
                                barWidth: 3,
                                isCurved: true,
                                spots: const <FlSpot>[
                                  FlSpot(0, 2),
                                  FlSpot(1, 4),
                                  FlSpot(2, 6),
                                  FlSpot(3, 8),
                                  FlSpot(4, 7),
                                  FlSpot(5, 9),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mood Trends',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(
                              7,
                              (index) => BarChartGroupData(
                                x: index,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: (index + 2).toDouble(),
                                    color: Theme.of(context).colorScheme.secondary,
                                    width: 10,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Apple Health',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPremium
                            ? 'Connect to see sleep and activity improvements.'
                            : 'Premium required to unlock health insights.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: isPremium
                            ? () async {
                                final granted =
                                    await HealthService.instance.requestAuthorization();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(granted
                                        ? 'Apple Health connected.'
                                        : 'Health permissions denied.'),
                                  ),
                                );
                              }
                            : null,
                        child: const Text('Connect Apple Health'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
