import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/anonymous_name.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class DmInboxScreen extends ConsumerWidget {
  const DmInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final threadsAsync = ref.watch(dmThreadsProvider);

    if (session == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to use direct messages.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: threadsAsync.when(
        data: (threads) {
          if (threads.isEmpty) {
            return const Center(child: Text('No messages yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final otherUserId =
                  thread.userA == session.user.id ? thread.userB : thread.userA;
              final alias = anonymousNameFor(otherUserId);
              return SectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(alias),
                  subtitle: Text('Last activity ${Formatters.timeAgo(thread.lastMessageAt)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/dm/thread/${thread.id}', extra: alias),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: threads.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed: $error')),
      ),
    );
  }
}
