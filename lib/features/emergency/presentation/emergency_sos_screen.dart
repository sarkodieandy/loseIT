import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/services/emergency_sos_service.dart';
import '../../../providers/data_providers.dart';

class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _breatheAnimController;

  Timer? _elapsedTimer;
  String? _activeSessionId;
  bool _breathing = false;
  bool _contactedSupport = false;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _breatheAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breatheAnimController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _startBreathingExercise() async {
    if (_breathing) return;

    setState(() {
      _breathing = true;
      _contactedSupport = false;
      _secondsElapsed = 0;
      _activeSessionId = null;
    });

    final session = await EmergencySosService.instance.startEmergencySOS(
      technique: 'breathing',
    );
    if (!mounted) return;
    if (session != null) {
      setState(() => _activeSessionId = session.id);
      AppLogger.info('sos: breathing exercise started');
    }

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_breathing) return;
      setState(() => _secondsElapsed += 1);
    });
  }

  void _stopBreathingExercise() async {
    if (!_breathing) return;
    _elapsedTimer?.cancel();
    final sessionId = _activeSessionId ??
        DateTime.now().millisecondsSinceEpoch.toString(); // fallback
    final durationSeconds = _secondsElapsed;
    final contactedSupport = _contactedSupport;

    setState(() {
      _breathing = false;
      _activeSessionId = null;
    });

    await EmergencySosService.instance.completeSession(
      sessionId: sessionId,
      technique: 'breathing',
      durationSeconds: durationSeconds,
      contactedSupport: contactedSupport,
      notes: 'Breathing exercise completed',
    );
  }

  void _contactSupport() {
    setState(() => _contactedSupport = true);
    AppLogger.info('sos: contact support');
    context.push('/support');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Mode'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.outline,
          indicatorColor: colorScheme.primary,
          tabs: const <Widget>[
            Tab(text: 'Urge Surf', icon: Icon(Icons.waves_rounded)),
            Tab(text: 'Breathing', icon: Icon(Icons.air_rounded)),
            Tab(text: 'Grounding', icon: Icon(Icons.spa_rounded)),
            Tab(text: 'Plan', icon: Icon(Icons.checklist_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          _UrgeSurfTab(
            onStartUrgeTimer: () => context.push('/focus/urge'),
            onOpenCravingRescue: () => context.push('/focus'),
            onOpenPlan: () => context.push('/recovery-plan'),
          ),
          _BreathingExerciseTab(
            breathing: _breathing,
            secondsElapsed: _secondsElapsed,
            breatheAnimController: _breatheAnimController,
            onStart: _startBreathingExercise,
            onStop: _stopBreathingExercise,
            onContact: _contactSupport,
          ),
          _GroundingTab(onContact: _contactSupport),
          const _PlanTab(),
        ],
      ),
    );
  }
}

class _UrgeSurfTab extends StatelessWidget {
  const _UrgeSurfTab({
    required this.onStartUrgeTimer,
    required this.onOpenCravingRescue,
    required this.onOpenPlan,
  });

  final VoidCallback onStartUrgeTimer;
  final VoidCallback onOpenCravingRescue;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Urge Surf',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Urges peak and fall like waves. Your job is to stay on the board for the next few minutes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onStartUrgeTimer,
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Start timer'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenCravingRescue,
                    icon: const Icon(Icons.headphones),
                    label: const Text('Craving audio'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.checklist_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Make your plan now so you can follow it later — even when you’re stressed.',
                  style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onOpenPlan,
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mini steps',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        const _MiniStep(
          index: 1,
          text: 'Change your environment (stand up, move rooms, go outside).',
        ),
        const SizedBox(height: 8),
        const _MiniStep(
          index: 2,
          text: 'Name the urge: “This is just a wave. It will pass.”',
        ),
        const SizedBox(height: 8),
        const _MiniStep(
          index: 3,
          text: 'Do 60 seconds of breathing or grounding — then repeat.',
        ),
      ],
    );
  }
}

class _MiniStep extends StatelessWidget {
  const _MiniStep({
    required this.index,
    required this.text,
  });

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingExerciseTab extends StatelessWidget {
  const _BreathingExerciseTab({
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mm = (secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (secondsElapsed % 60).toString().padLeft(2, '0');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Breathing reset',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Follow the circle: inhale… hold… exhale…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1.35).animate(
              CurvedAnimation(
                parent: breatheAnimController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.65),
                  width: 3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            '$mm:$ss',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: breathing ? colorScheme.error : null,
            ),
            onPressed: breathing ? onStop : onStart,
            child: Text(breathing ? 'Stop' : 'Start'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Contact support'),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tip: keep the exhale longer than the inhale.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
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
        FilledButton.icon(
          onPressed: onContact,
          icon: const Icon(Icons.support_agent_rounded),
          label: const Text('Need more support?'),
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

class _PlanTab extends ConsumerWidget {
  const _PlanTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(recoveryPlanProvider);
    final scheme = Theme.of(context).colorScheme;

    Widget chipRow(String title, List<String> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map(
                  (e) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        e,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        SectionCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.checklist_rounded, color: scheme.primary),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Your plan is here when you need it. Keep it short and real.',
                  style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => context.push('/recovery-plan'),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        planAsync.when(
          data: (plan) {
            if (plan == null) {
              return SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'No plan yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a quick plan for high‑risk moments (triggers, warning signs, go‑to actions).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.push('/recovery-plan'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create plan'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                chipRow('Top triggers', plan.triggers),
                chipRow('Warning signs', plan.warningSigns),
                chipRow('Go‑to actions', plan.copingActions),
                if ((plan.supportMessage ?? '').trim().isNotEmpty) ...[
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Support message',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.supportMessage!.trim(),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: plan.supportMessage!.trim()),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied.')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const SectionCard(
            child: SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (error, _) => SectionCard(
            child: Text(error.toString()),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () => context.push('/focus/urge'),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Urge timer'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/focus'),
              icon: const Icon(Icons.headphones),
              label: const Text('Craving audio'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/support'),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Support'),
            ),
          ],
        ),
      ],
    );
  }
}
