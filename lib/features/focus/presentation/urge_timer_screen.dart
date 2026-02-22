import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_logger.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class _UrgeColors {
  static const Color bgTop = Color(0xFF050607);
  static const Color bgBottom = Color(0xFF0B0E11);
  static const Color card = Color(0xFF0E1216);
  static const Color cardBorder = Color(0x1AFFFFFF);
  static const Color muted = Color(0xFF9AA3AB);
  static const Color accent = Color(0xFF26B7FF);
}

class UrgeTimerScreen extends ConsumerStatefulWidget {
  const UrgeTimerScreen({super.key});

  @override
  ConsumerState<UrgeTimerScreen> createState() => _UrgeTimerScreenState();
}

class _UrgeTimerScreenState extends ConsumerState<UrgeTimerScreen>
    with SingleTickerProviderStateMixin {
  static const List<Duration> _durations = <Duration>[
    Duration(seconds: 90),
    Duration(minutes: 3),
    Duration(minutes: 5),
    Duration(minutes: 10),
  ];

  Duration _selected = _durations[2];
  late AnimationController _timer;
  late AnimationController _breath;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _timer = AnimationController(vsync: this, duration: _selected);
    _breath = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _timer.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() => _running = false);
        HapticFeedback.mediumImpact();
        await _showLogSheet();
      }
    });
  }

  @override
  void dispose() {
    _timer.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _resetTimer() {
    _timer.stop();
    _timer.value = 0;
    setState(() => _running = false);
  }

  void _start() {
    if (_running) return;
    _timer.duration = _selected;
    _timer.forward(from: 0);
    setState(() => _running = true);
    HapticFeedback.selectionClick();
  }

  void _togglePause() {
    if (!_running) return;
    if (_timer.isAnimating) {
      _timer.stop();
    } else {
      _timer.forward();
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _showLogSheet() async {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    // Ensure profile exists (so we can route user back to onboarding if needed).
    final profile = ref.read(profileControllerProvider).asData?.value;
    if (profile == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete onboarding to save logs.')),
      );
      context.go('/onboarding');
      return;
    }

    final intensity = ValueNotifier<double>(6);
    final triggerController = TextEditingController();
    final noteController = TextEditingController();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _UrgeColors.card,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Log the urge',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: intensity,
                  builder: (context, value, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Intensity: ${value.toInt()}/10',
                        style: const TextStyle(
                          color: _UrgeColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Slider(
                        min: 1,
                        max: 10,
                        divisions: 9,
                        value: value,
                        onChanged: (v) => intensity.value = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: triggerController,
                  decoration: const InputDecoration(
                    labelText: 'Trigger (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _UrgeColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            setModalState(() => saving = true);
                            try {
                              await ref.read(urgeRepositoryProvider).createLog(
                                    intensity: intensity.value.toInt(),
                                    trigger: triggerController.text.trim(),
                                    note: noteController.text.trim(),
                                  );
                              ref.invalidate(urgeLogsProvider);
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Urge logged.')),
                              );
                            } catch (error, stackTrace) {
                              AppLogger.error('urge.log', error, stackTrace);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            } finally {
                              if (context.mounted) setModalState(() => saving = false);
                            }
                          },
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _UrgeColors.bgTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Urge Timer'),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    _UrgeColors.bgTop,
                    _UrgeColors.bgBottom,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _UrgeColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: _UrgeColors.cardBorder),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.timer_outlined, color: _UrgeColors.muted),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Ride the wave. You don’t have to act on it.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<Duration>(
                          value: _selected,
                          dropdownColor: _UrgeColors.card,
                          items: _durations
                              .map(
                                (d) => DropdownMenuItem<Duration>(
                                  value: d,
                                  child: Text(
                                    d.inSeconds == 90 ? '1:30' : '${d.inMinutes} min',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _running
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setState(() => _selected = value);
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: Listenable.merge(<Listenable>[_timer, _breath]),
                      builder: (context, _) {
                        final progress = _timer.value.clamp(0.0, 1.0);
                        final totalSeconds = (_timer.duration ?? _selected).inSeconds;
                        final remainingSeconds = math.max(
                          0,
                          (totalSeconds * (1 - progress)).ceil(),
                        );
                        final mm =
                            (remainingSeconds ~/ 60).toString().padLeft(2, '0');
                        final ss =
                            (remainingSeconds % 60).toString().padLeft(2, '0');
                        final breath = 0.92 + 0.10 * math.sin(_breath.value * math.pi * 2);
                        final ring = 1.0 - progress;
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            Transform.scale(
                              scale: breath,
                              child: Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: <Color>[
                                      _UrgeColors.accent.withValues(alpha: 0.22),
                                      _UrgeColors.bgTop,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: _UrgeColors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 260,
                              height: 260,
                              child: CircularProgressIndicator(
                                value: ring,
                                strokeWidth: 10,
                                color: _UrgeColors.accent,
                                backgroundColor:
                                    _UrgeColors.accent.withValues(alpha: 0.12),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  '$mm:$ss',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _running
                                      ? (_timer.isAnimating ? 'Breathe' : 'Paused')
                                      : 'Ready',
                                  style: const TextStyle(
                                    color: _UrgeColors.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _running ? _togglePause : _start,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: _UrgeColors.cardBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _running
                              ? (_timer.isAnimating ? 'Pause' : 'Resume')
                              : 'Start',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _running ? _resetTimer : () => context.pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: _UrgeColors.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _running ? 'End' : 'Done',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tip: tell yourself “I can do anything for 60 seconds.” Then repeat.',
                  style: TextStyle(
                    color: _UrgeColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
