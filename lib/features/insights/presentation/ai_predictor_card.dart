import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/section_card.dart';
import '../../../data/models/relapse_prediction.dart';

class AiPredictorCard extends ConsumerWidget {
  const AiPredictorCard({
    super.key,
    required this.prediction,
  });

  final RelapsePrediction prediction;

  Color _getRiskColor(String riskLevel) {
    return switch (riskLevel) {
      'critical' => Colors.red,
      'high' => Colors.orange,
      'medium' => Colors.amber,
      'low' => Colors.green,
      _ => Colors.grey,
    };
  }

  IconData _getRiskIcon(String riskLevel) {
    return switch (riskLevel) {
      'critical' => Icons.warning,
      'high' => Icons.error_outline,
      'medium' => Icons.info,
      'low' => Icons.check_circle,
      _ => Icons.help,
    };
  }

  String _getRiskDescription(String riskLevel) {
    return switch (riskLevel) {
      'critical' => 'Critical Risk - Get support now',
      'high' => 'High Risk - Use coping tools',
      'medium' => 'Moderate Risk - Stay alert',
      'low' => 'Low Risk - You\'re doing great',
      _ => 'Unknown',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getRiskColor(prediction.riskLevel);
    final icon = _getRiskIcon(prediction.riskLevel);
    final showCta =
        prediction.riskLevel == 'critical' || prediction.riskLevel == 'high';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header with risk score
          Row(
            children: <Widget>[
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '${prediction.riskScore}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      Text(
                        '%',
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(icon, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _getRiskDescription(prediction.riskLevel),
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: prediction.riskScore / 100,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Top triggers
          if (prediction.topTriggers.isNotEmpty) ...[
            Text(
              'Your Top Triggers Today',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ...prediction.topTriggers.map((trigger) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      trigger,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // Recommendations
          if (prediction.recommendations.isNotEmpty) ...[
            Text(
              'Recommended Actions',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ...prediction.recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final recommendation = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < 2 ? 8 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          if (showCta) ...[
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/emergency-sos'),
                    icon: const Icon(Icons.emergency_rounded),
                    label: const Text('Open SOS'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/focus/urge'),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Urge timer'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Confidence indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'AI Confidence',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '${prediction.confidence}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: prediction.confidence / 100,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
