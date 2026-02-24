late final List<_FocusTrack> _tracks = <_FocusTrack>[
  _FocusTrack(
    id: 'breath_free',
    title: '90s Breathing Reset',
    duration: '1:30',
    isPremium: false,
    url: _envOrAsset('FOCUS_TRACK_BREATH', 'assets/audio.mp3'),

  ),
  _FocusTrack(
    id: 'craving_release',
    title: 'Craving Release',
    duration: '5:00',
    isPremium: true,
    url: _envOrAsset('FOCUS_TRACK_CRAVING', 'assets/audio.mp3'),

  ),
  _FocusTrack(
    id: 'night_wind_down',
    title: 'Night Wind Down',
    duration: '7:00',
    isPremium: true,
    url: _envOrAsset('FOCUS_TRACK_WIND_DOWN', 'assets/assets/audio.mp3'),
  ),
];

String _envOrAsset(String key, String assetPath) {
  
  final val = dotenv.env[key]?.trim();
  if (val != null && val.isNotEmpty) return val;
  return assetPath;
}import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../emergency_flow.dart';
import '../widgets/breathing_orb.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key, this.onExit, required this.showClose});

  final VoidCallback? onExit;
  final bool showClose;

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _countdown;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat(reverse: true);

    _countdown = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 90),
    )..forward();

    _countdown.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacementNamed(EmergencyFlow.intervention);
      }
    });
  }

  @override
  void dispose() {
    _breath.dispose();
    _countdown.dispose();
    super.dispose();
  }

  String _formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DisciplineScaffold(
      title: 'Breathing',
      trailing: widget.showClose
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onExit,
              child: const Icon(
                CupertinoIcons.xmark,
                color: DisciplineColors.textSecondary,
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[_breath, _countdown]),
        builder: (context, _) {
          final remaining = ((1 - _countdown.value) * 90).ceil().clamp(0, 90);
          final inhale = _breath.status == AnimationStatus.forward;

          return Column(
            children: <Widget>[
              const Spacer(),
              BreathingOrb(t: _breath.value),
              const SizedBox(height: 26),
              Text(
                inhale ? 'Inhale' : 'Exhale',
                style: DisciplineTextStyles.section.copyWith(
                  color: DisciplineColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatSeconds(remaining),
                style: DisciplineTextStyles.caption.copyWith(
                  color: DisciplineColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Stay with the breath. Let the wave pass.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  EmergencyFlow.intervention,
                ),
                child: Text(
                  'Skip',
                  style: DisciplineTextStyles.caption.copyWith(
                    color: DisciplineColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
