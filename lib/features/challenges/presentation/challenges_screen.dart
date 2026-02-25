import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);
    final userChallengesAsync = ref.watch(userChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Create group',
            onPressed: () => context.push('/groups/new'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          challengesAsync.when(
            data: (challenges) {
              if (challenges.isEmpty) {
                return const SectionCard(child: Text('No groups yet.'));
              }
              final userChallenges = userChallengesAsync.value ?? const [];
              return Column(
                children: challenges.map((challenge) {
                  final joined = userChallenges
                      .any((item) => item.challengeId == challenge.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SectionCard(
                      child: InkWell(
                        onTap: () => context.push('/groups/${challenge.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      challenge.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: joined
                                        ? null
                                        : () async {
                                            await ref
                                                .read(
                                                    challengesRepositoryProvider)
                                                .startChallenge(challenge.id);
                                            ref.invalidate(
                                                userChallengesProvider);
                                            ref.invalidate(challengesProvider);
                                            await NotificationService()
                                                .refreshGroupChatSubscriptions();
                                          },
                                    child: Text(joined ? 'Joined' : 'Join'),
                                  ),
                                ],
                              ),
                              if (challenge.description != null &&
                                  challenge.description!.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(challenge.description!),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '${challenge.memberCount} members',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
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
    );
  }
}
