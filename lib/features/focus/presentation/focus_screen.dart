import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_motion.dart';
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
  _FocusTrack? _currentTrack;
  PlayerState _playerState = PlayerState.stopped;
  bool _scrubbing = false;

  final ValueNotifier<Duration> _position = ValueNotifier<Duration>(
    Duration.zero,
  );
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );

  StreamSubscription<void>? _playerCompleteSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;

  static const String _defaultAudioAsset = 'audio.mp3';

  late final List<_FocusTrack> _tracks = <_FocusTrack>[
    _FocusTrack(
      id: 'breath_free',
      title: '90s Breathing Reset',
      subtitle: 'Quick reset when the urge spikes',
      duration: '1:30',
      isPremium: false,
      icon: Icons.air_rounded,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'grounding_3',
      title: '3‑Minute Grounding',
      subtitle: 'Back to the present moment',
      duration: '3:00',
      isPremium: false,
      icon: Icons.spa_rounded,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'craving_release',
      title: 'Craving Release',
      subtitle: 'Ride the wave, then let it go',
      duration: '5:00',
      isPremium: true,
      icon: Icons.waves_rounded,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'body_scan',
      title: 'Body Scan',
      subtitle: 'Unclench tension, soften the urge',
      duration: '6:00',
      isPremium: true,
      icon: Icons.self_improvement_rounded,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'night_wind_down',
      title: 'Night Wind Down',
      subtitle: 'Calm your mind before sleep',
      duration: '7:00',
      isPremium: true,
      icon: Icons.nightlight_round,
      url: _defaultAudioAsset,
    ),
    _FocusTrack(
      id: 'confidence_boost',
      title: 'Confidence Boost',
      subtitle: 'Remember why you started',
      duration: '4:00',
      isPremium: true,
      icon: Icons.emoji_events_rounded,
      url: _defaultAudioAsset,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playerState = state);
    });

    _durationSub = _player.onDurationChanged.listen((duration) {
      _duration.value = duration;
    });

    _positionSub = _player.onPositionChanged.listen((position) {
      if (_scrubbing) return;
      _position.value = position;
    });

    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      _position.value = Duration.zero;
      if (!mounted) return;
      setState(() => _playerState = PlayerState.stopped);
    });
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _playerStateSub?.cancel();
    _durationSub?.cancel();
    _positionSub?.cancel();
    _position.dispose();
    _duration.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startTrack(_FocusTrack track) async {
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
      _position.value = Duration.zero;
      _duration.value = Duration.zero;
      await _player.play(AssetSource(track.url));
      if (!mounted) return;
      setState(() => _currentTrack = track);
    } catch (e, st) {
      AppLogger.error('focus.play', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play audio.')),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_playerState == PlayerState.playing) {
        await _player.pause();
      } else if (_playerState == PlayerState.paused) {
        await _player.resume();
      } else {
        final track = _currentTrack;
        if (track == null) return;
        await _startTrack(track);
      }
    } catch (e, st) {
      AppLogger.error('focus.toggle', e, st);
    }
  }

  Future<void> _stop({bool clearSelection = false}) async {
    try {
      await _player.stop();
    } catch (_) {}
    _position.value = Duration.zero;
    if (!mounted) return;
    setState(() {
      _playerState = PlayerState.stopped;
      if (clearSelection) _currentTrack = null;
    });
  }

  String _formatClock(Duration value) {
    final totalSeconds = value.inSeconds.clamp(0, 24 * 3600);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(premiumControllerProvider);
    final urgeLogsAsync = ref.watch(urgeLogsProvider);
    final hasPremiumAccess = status.hasAccess;
    final bottomPadding = _currentTrack == null ? 20.0 : 152.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Craving Rescue')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
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
            final isSelected = _currentTrack?.id == track.id;
            final isPlaying = isSelected && _playerState == PlayerState.playing;
            final isPaused = isSelected && _playerState == PlayerState.paused;

            return _SessionTile(
              title: track.title,
              subtitle: track.subtitle,
              durationLabel: track.duration,
              icon: track.icon,
              premium: track.isPremium,
              locked: locked,
              active: isSelected,
              playing: isPlaying,
              paused: isPaused,
              onTap: () {
                if (locked) {
                  context.push('/paywall');
                  return;
                }
                if (!isSelected) {
                  unawaited(_startTrack(track));
                  return;
                }
                unawaited(_togglePlayPause());
              },
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
      bottomNavigationBar: AnimatedSwitcher(
        duration: AppMotion.medium,
        switchInCurve: AppMotion.emphasized,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) {
          final curved =
              CurvedAnimation(parent: animation, curve: AppMotion.emphasized);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        child: _currentTrack == null
            ? const SizedBox.shrink()
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _NowPlayingBar(
                    key: ValueKey('now_playing_${_currentTrack!.id}'),
                    title: _currentTrack!.title,
                    subtitle: _currentTrack!.subtitle,
                    playing: _playerState == PlayerState.playing,
                    onPlayPause: () => unawaited(_togglePlayPause()),
                    onClose: () => unawaited(_stop(clearSelection: true)),
                    position: _position,
                    duration: _duration,
                    formatClock: _formatClock,
                    onSeekPreview: (nextPosition) {
                      _position.value = nextPosition;
                    },
                    onSeekCommitted: (nextPosition) async {
                      _position.value = nextPosition;
                      try {
                        await _player.seek(nextPosition);
                      } catch (e, st) {
                        AppLogger.error('focus.seek', e, st);
                      }
                    },
                    onScrubChanged: (scrubbing) {
                      _scrubbing = scrubbing;
                    },
                    onSkip: (delta) async {
                      final total = _duration.value;
                      final current = _position.value;
                      final target = current + delta;
                      final totalMs = total.inMilliseconds;
                      final targetMs = target.inMilliseconds;
                      final clampedMs = totalMs > 0
                          ? targetMs.clamp(0, totalMs).toInt()
                          : targetMs < 0
                              ? 0
                              : targetMs;
                      final clamped = Duration(milliseconds: clampedMs);
                      try {
                        await _player.seek(clamped);
                      } catch (e, st) {
                        AppLogger.error('focus.skip', e, st);
                      }
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _FocusTrack {
  const _FocusTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.isPremium,
    required this.icon,
    required this.url,
  });

  final String id;
  final String title;
  final String subtitle;
  final String duration;
  final bool isPremium;
  final IconData icon;
  final String url;
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.title,
    required this.subtitle,
    required this.durationLabel,
    required this.icon,
    required this.premium,
    required this.locked,
    required this.active,
    required this.playing,
    required this.paused,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String durationLabel;
  final IconData icon;
  final bool premium;
  final bool locked;
  final bool active;
  final bool playing;
  final bool paused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).cardTheme.color ?? scheme.surface;
    final border = active
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outlineVariant.withValues(alpha: 0.35);
    final iconBg = active
        ? scheme.primary.withValues(alpha: 0.16)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.75);
    final iconColor = active ? scheme.primary : scheme.onSurface;

    final trailingIcon = locked
        ? Icons.lock_rounded
        : playing
            ? Icons.pause_rounded
            : Icons.play_arrow_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border),
              boxShadow: <BoxShadow>[
                if (active)
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Opacity(
              opacity: locked ? 0.65 : 1,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: iconBg,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            if (premium) ...[
                              const SizedBox(width: 8),
                              _Pill(
                                label: locked ? 'Premium' : 'Pro',
                                icon: locked
                                    ? Icons.lock_rounded
                                    : Icons.star_rounded,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        durationLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? scheme.primary.withValues(alpha: 0.14)
                              : scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                          border: Border.all(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Icon(trailingIcon, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingBar extends StatelessWidget {
  const _NowPlayingBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.playing,
    required this.onPlayPause,
    required this.onClose,
    required this.position,
    required this.duration,
    required this.formatClock,
    required this.onSeekPreview,
    required this.onSeekCommitted,
    required this.onScrubChanged,
    required this.onSkip,
  });

  final String title;
  final String subtitle;
  final bool playing;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;
  final ValueListenable<Duration> position;
  final ValueListenable<Duration> duration;
  final String Function(Duration value) formatClock;
  final ValueChanged<Duration> onSeekPreview;
  final ValueChanged<Duration> onSeekCommitted;
  final ValueChanged<bool> onScrubChanged;
  final ValueChanged<Duration> onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget compactIconButton({
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: Icon(icon),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return Material(
          color: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.95),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.30),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            scheme.primary.withValues(alpha: 0.26),
                            scheme.secondary.withValues(alpha: 0.18),
                          ],
                        ),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Icon(
                        playing
                            ? Icons.graphic_eq_rounded
                            : Icons.headphones_rounded,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact)
                      compactIconButton(
                        tooltip: 'Back 10s',
                        icon: Icons.replay_10_rounded,
                        onPressed: () => onSkip(const Duration(seconds: -10)),
                      ),
                    IconButton(
                      tooltip: playing ? 'Pause' : 'Play',
                      onPressed: onPlayPause,
                      icon: Icon(
                        playing
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 38,
                        color: scheme.primary,
                      ),
                    ),
                    if (!compact)
                      compactIconButton(
                        tooltip: 'Forward 10s',
                        icon: Icons.forward_10_rounded,
                        onPressed: () => onSkip(const Duration(seconds: 10)),
                      ),
                    compactIconButton(
                      tooltip: 'Close player',
                      icon: Icons.close_rounded,
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Duration>(
                  valueListenable: duration,
                  builder: (context, total, _) =>
                      ValueListenableBuilder<Duration>(
                    valueListenable: position,
                    builder: (context, pos, __) {
                      final totalMs = total.inMilliseconds;
                      final posMs = totalMs > 0
                          ? pos.inMilliseconds.clamp(0, totalMs).toInt()
                          : pos.inMilliseconds;
                      final enabled = totalMs > 0;

                      final slider = SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          activeTrackColor: scheme.primary,
                          inactiveTrackColor:
                              scheme.primary.withValues(alpha: 0.22),
                          thumbColor: scheme.primary,
                          overlayColor: scheme.primary.withValues(alpha: 0.12),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.5,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: enabled ? posMs.toDouble() : 0,
                          min: 0,
                          max: enabled ? totalMs.toDouble() : 1,
                          onChangeStart:
                              enabled ? (_) => onScrubChanged(true) : null,
                          onChanged: enabled
                              ? (value) {
                                  onSeekPreview(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                }
                              : null,
                          onChangeEnd: enabled
                              ? (value) {
                                  onScrubChanged(false);
                                  onSeekCommitted(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                }
                              : null,
                        ),
                      );

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (compact)
                            Row(
                              children: <Widget>[
                                compactIconButton(
                                  tooltip: 'Back 10s',
                                  icon: Icons.replay_10_rounded,
                                  onPressed: () =>
                                      onSkip(const Duration(seconds: -10)),
                                ),
                                Expanded(child: slider),
                                compactIconButton(
                                  tooltip: 'Forward 10s',
                                  icon: Icons.forward_10_rounded,
                                  onPressed: () =>
                                      onSkip(const Duration(seconds: 10)),
                                ),
                              ],
                            )
                          else
                            slider,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  formatClock(Duration(milliseconds: posMs)),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  enabled ? formatClock(total) : '--:--',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
