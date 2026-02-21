import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/premium_gate.dart';
import '../../../core/widgets/section_card.dart';
import '../../../providers/app_providers.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Craving Rescue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
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
