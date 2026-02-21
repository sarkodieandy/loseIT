import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/community/new'),
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
      body: feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No posts yet. Be the first.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final post = posts[index];
              return SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          post.anonymousName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          Formatters.timeAgo(post.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(post.content),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () async {
                            await ref
                                .read(communityRepositoryProvider)
                                .likePost(post.id, post.likes);
                          },
                          icon: const Icon(Icons.favorite_border),
                        ),
                        Text('${post.likes}'),
                      ],
                    ),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: posts.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/community/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
