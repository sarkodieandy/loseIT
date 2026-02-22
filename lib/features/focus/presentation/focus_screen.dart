import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? _currentId;

  final List<_FocusTrack> _tracks = const <_FocusTrack>[
    _FocusTrack(
      id: 'breath_free',
      title: '90s Breathing Reset',
      duration: '1:30',
      isPremium: false,
      url: '',
    ),
    _FocusTrack(
      id: 'craving_release',
      title: 'Craving Release',
      duration: '5:00',
      isPremium: true,
      url: '',
    ),
    _FocusTrack(
      id: 'night_wind_down',
      title: 'Night Wind Down',
      duration: '7:00',
      isPremium: true,
      url: '',
    ),
  ];

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(_FocusTrack track, bool isPremium) async {
    if (track.isPremium && !isPremium) return;
    if (_currentId == track.id) {
      await _player.stop();
      setState(() => _currentId = null);
      return;
    }
    if (track.url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio not configured yet.')),
      );
      return;
    }
    await _player.play(UrlSource(track.url));
    setState(() => _currentId = track.id);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumControllerProvider);
    final urgeLogsAsync = ref.watch(urgeLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Craving Rescue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SectionCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Start an urge timer and ride it out with a breathing guide.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/focus/urge'),
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Text(
              'Take a breath. These guided sessions help you ride out the craving.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          ..._tracks.map((track) {
            final locked = track.isPremium && !isPremium;
            final card = SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(track.title),
                subtitle: Text(track.duration),
                trailing: Icon(
                  _currentId == track.id ? Icons.stop : Icons.play_arrow,
                ),
                onTap: () => _play(track, isPremium),
              ),
            );
            if (!locked) return card;
            return PremiumGate(
              lockedTitle: track.title,
              lockedDescription: 'Premium session',
              child: card,
            );
          }),
          const SizedBox(height: 16),
          urgeLogsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const SectionCard(
                  child: Text('No urge logs yet.'),
                );
              }
              final recent = logs.take(5).toList(growable: false);
              return SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recent Urges',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...recent.map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• ${log.intensity}/10 · ${log.trigger ?? '—'} · '
                          '${log.occurredAt.month}/${log.occurredAt.day} ${log.occurredAt.hour.toString().padLeft(2, '0')}:${log.occurredAt.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, _) => SectionCard(child: Text('Urge logs failed: $error')),
          ),
        ],
      ),
    );
  }
}

class _FocusTrack {
  const _FocusTrack({
    required this.id,
    required this.title,
    required this.duration,
    required this.isPremium,
    required this.url,
  });

  final String id;
  final String title;
  final String duration;
  final bool isPremium;
  final String url;
}
