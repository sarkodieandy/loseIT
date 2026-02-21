import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/data_providers.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'journal_fab',
        onPressed: () => context.push('/journal/new'),
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No entries yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return GestureDetector(
                onTap: () => context.push('/journal/${entry.id}'),
                child: SectionCard(
                  child: Row(
                    children: <Widget>[
                      if (entry.photoUrl != null) ...[
                        Hero(
                          tag: 'journal_photo_${entry.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              entry.photoUrl!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              Formatters.date.format(entry.entryDate),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(entry.preview),
                            if (entry.mood != null) ...[
                              const SizedBox(height: 6),
                              Text('Mood: ${entry.mood}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: entries.length,
          );
        },
        loading: () => const _JournalLoading(),
        error: (error, _) => Center(child: Text('Failed to load: $error')),
      ),
    );
  }
}

class _JournalLoading extends StatelessWidget {
  const _JournalLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListView.separated(
          itemBuilder: (context, index) => Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: 6,
        ),
      ),
    );
  }
}
