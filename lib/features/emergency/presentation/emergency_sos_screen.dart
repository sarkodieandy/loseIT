import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/services/emergency_sos_service.dart';

class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _secondsElapsed = 0;
  bool _breathing = false;
  late AnimationController _breatheAnimController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _breatheAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breatheAnimController.dispose();
    super.dispose();
  }

  void _startBreathingExercise() async {
    setState(() => _breathing = true);
    final session = await EmergencySosService.instance
        .startEmergencySOS(technique: 'breathing');
    if (session != null) {
      AppLogger.info('sos: breathing exercise started');
    }
  }

  void _stopBreathingExercise() async {
    setState(() => _breathing = false);
    await EmergencySosService.instance.completeSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      durationSeconds: _secondsElapsed,
      contactedSupport: false,
      notes: 'Breathing exercise completed',
    );
  }

  void _contactSupport() {
    AppLogger.info('sos: contacting support network');
    // This would open a modal to contact support network
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifying your support network...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Support'),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          // Tab selector
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.outline,
              indicatorColor: colorScheme.primary,
              tabs: const <Widget>[
                Tab(text: '🫁 Breathing'),
                Tab(text: '🧠 Grounding'),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                // Breathing Exercise
                _BreathingTab(
                  breathing: _breathing,
                  secondsElapsed: _secondsElapsed,
                  breatheAnimController: _breatheAnimController,
                  onStart: _startBreathingExercise,
                  onStop: _stopBreathingExercise,
                  onContact: _contactSupport,
                ),
                // Grounding Technique
                _GroundingTab(
                  onContact: _contactSupport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingTab extends StatefulWidget {
  const _BreathingTab({
    required this.breathing,
    required this.secondsElapsed,
    required this.breatheAnimController,
    required this.onStart,
    required this.onStop,
    required this.onContact,
  });

  final bool breathing;
  final int secondsElapsed;
  final AnimationController breatheAnimController;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onContact;

  @override
  State<_BreathingTab> createState() => _BreathingTabState();
}

class _BreathingTabState extends State<_BreathingTab> {
  late int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (widget.breathing && mounted) {
        setState(() => _seconds++);
      }
      return widget.breathing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 20),
          Text(
            'Follow the circle',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Breathe in slowly, hold, then exhale.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          // Breathing animation circle
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.5)
                .animate(widget.breatheAnimController),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.2),
                border: Border.all(
                  color: colorScheme.primary,
                  width: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                    widget.breathing ? colorScheme.error : colorScheme.primary,
              ),
              onPressed: widget.breathing ? widget.onStop : widget.onStart,
              child:
                  Text(widget.breathing ? 'Stop Exercise' : 'Start Exercise'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: widget.onContact,
              child: const Text('Contact Support Network'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroundingTab extends StatelessWidget {
  const _GroundingTab({
    required this.onContact,
  });

  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        const SizedBox(height: 16),
        Text(
          '5-4-3-2-1 Grounding Technique',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        _GroundingStep(
          number: 5,
          title: 'Name 5 things you can SEE',
          examples: 'Wall, phone, window, light, door',
        ),
        const SizedBox(height: 16),
        _GroundingStep(
          number: 4,
          title: 'Name 4 things you can TOUCH',
          examples: 'Soft blanket, cold water, warm cup, smooth desk',
        ),
        const SizedBox(height: 16),
        _GroundingStep(
          number: 3,
          title: 'Name 3 things you can HEAR',
          examples: 'Birds, traffic, breathing, music',
        ),
        const SizedBox(height: 16),
        _GroundingStep(
          number: 2,
          title: 'Name 2 things you can SMELL',
          examples: 'Coffee, flowers, air freshener, mint',
        ),
        const SizedBox(height: 16),
        _GroundingStep(
          number: 1,
          title: 'Name 1 thing you can TASTE',
          examples: 'Mint, gum, candy, tea',
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: onContact,
          child: const Text('Need More Support?'),
        ),
      ],
    );
  }
}

class _GroundingStep extends StatelessWidget {
  const _GroundingStep({
    required this.number,
    required this.title,
    required this.examples,
  });

  final int number;
  final String title;
  final String examples;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            examples,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
