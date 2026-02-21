import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumControllerProvider);
    final challengesAsync = ref.watch(challengesProvider);
    final userChallengesAsync = ref.watch(userChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: PremiumGate(
        lockedTitle: 'Recovery Challenges',
        lockedDescription: 'Upgrade to join guided 30‑day challenges.',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            challengesAsync.when(
              data: (challenges) {
                if (challenges.isEmpty) {
                  return const SectionCard(child: Text('No challenges yet.'));
                }
                final userChallenges = userChallengesAsync.value ?? const [];
                return Column(
                  children: challenges.map((challenge) {
                    final joined = userChallenges
                        .any((item) => item.challengeId == challenge.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              challenge.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (challenge.description != null) ...[
                              const SizedBox(height: 6),
                              Text(challenge.description!),
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: !isPremium || joined
                                  ? null
                                  : () async {
                                      await ref
                                          .read(challengesRepositoryProvider)
                                          .startChallenge(challenge.id);
                                      ref.invalidate(userChallengesProvider);
                                    },
                              child: Text(joined ? 'Joined' : 'Join'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Failed: $error')),
            ),
          ],
        ),
      ),
    );
  }
}
