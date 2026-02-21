import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/journal_entry.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class JournalEntryScreen extends ConsumerStatefulWidget {
  const JournalEntryScreen({
    super.key,
    required this.entryId,
  });

  final String entryId;

  @override
  ConsumerState<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends ConsumerState<JournalEntryScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(String url) async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(UrlSource(url));
    setState(() => _playing = true);
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(journalControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Entry')),
      body: entriesAsync.when(
        data: (entries) {
          JournalEntry? entry;
          for (final item in entries) {
            if (item.id == widget.entryId) {
              entry = item;
              break;
            }
          }
          entry ??= entries.isNotEmpty ? entries.first : null;

          if (entry == null) {
            return const Center(child: Text('Entry not found.'));
          }
          final resolved = entry;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Text(
                Formatters.date.format(resolved.entryDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(resolved.content, style: Theme.of(context).textTheme.bodyLarge),
              if (resolved.photoUrl != null) ...[
                const SizedBox(height: 16),
                Hero(
                  tag: 'journal_photo_${resolved.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(resolved.photoUrl!, fit: BoxFit.cover),
                  ),
                ),
              ],
              if (resolved.mood != null) ...[
                const SizedBox(height: 12),
                Text('Mood: ${resolved.mood}'),
              ],
              if (resolved.transcript != null && resolved.transcript!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Transcription',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(resolved.transcript!),
              ],
              if (resolved.audioUrl != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _togglePlayback(resolved.audioUrl!),
                  icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                  label: Text(_playing ? 'Stop Audio' : 'Play Audio'),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  final repo = ref.read(journalRepositoryProvider);
                  final controller = ref.read(journalControllerProvider.notifier);
                  await repo.deleteEntry(resolved.id);
                  await controller.removeEntry(resolved.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Entry'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed: $error')),
      ),
    );
  }
}
