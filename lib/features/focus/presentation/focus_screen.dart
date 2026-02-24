import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_logger.dart';

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
  StreamSubscription<void>? _playerCompleteSub;

  static const String _defaultAudioAsset = 'audio.mp3';

  late final List<_FocusTrack> _tracks = <_FocusTrack>[
    _FocusTrack(
      id: 'breath_free',
      title: '90s Breathing Reset',
      duration: '1:30',
      isPremium: false,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'craving_release',
      title: 'Craving Release',
      duration: '5:00',
      isPremium: true,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'night_wind_down',
      title: 'Night Wind Down',
      duration: '7:00',
      isPremium: true,
      url: _defaultAudioAsset,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _currentId = null);
    });
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
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
        const SnackBar(content: Text('Audio file is missing.')),
      );
      AppLogger.warn('Attempted to play track with empty URL: ${track.id}');
      return;
    }

    try {
      // All sessions use the bundled asset for production stability.
      // audioplayers' default AudioCache prefix is `assets/`, so the asset path
      // must be relative (e.g. `audio.mp3`, not `assets/audio.mp3`).
      await _player.stop();
      await _player.play(AssetSource(track.url));
      setState(() => _currentId = track.id);
    } catch (e, st) {
      AppLogger.error('focus.play', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play audio.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(premiumControllerProvider);
    final urgeLogsAsync = ref.watch(urgeLogsProvider);
    final hasPremiumAccess = status.hasAccess;

    return Scaffold(
      appBar: AppBar(title: const Text('Craving Rescue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          // Emergency SOS Button
          PremiumGate(
            lockedTitle: 'Emergency Support',
            lockedDescription: 'Premium feature for crisis moments.',
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.push('/emergency-sos'),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              child: Icon(
                                Icons.emergency,
                                color: Theme.of(context).colorScheme.onError,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Emergency SOS',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Guided breathing & grounding',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // make whole card tappable for better UX
          GestureDetector(
            onTap: () {
              AppLogger.info('navigating to urge timer');
              try {
                context.push('/focus/urge');
              } catch (e) {
                AppLogger.error('router.push.urge', e, null);
              }
            },
            child: SectionCard(
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
                    onPressed: () {
                      AppLogger.info('timer button tapped');
                      context.push('/focus/urge');
                    },
                    child: const Text('Start'),
                  ),
                ],
              ),
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
            final locked = track.isPremium && !hasPremiumAccess;
            final card = SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(track.title),
                subtitle: Text(track.duration),
                trailing: Icon(
                  _currentId == track.id ? Icons.stop : Icons.play_arrow,
                ),
                onTap: () => _play(track, hasPremiumAccess),
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
            error: (error, _) =>
                SectionCard(child: Text('Urge logs failed: $error')),
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
