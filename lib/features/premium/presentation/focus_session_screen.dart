import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/focus_session.dart';
import '../../../providers/focus_financial_providers.dart';
import '../../../providers/app_providers.dart';

class FocusSessionScreen extends ConsumerStatefulWidget {
  const FocusSessionScreen({super.key});

  @override
  ConsumerState<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends ConsumerState<FocusSessionScreen> {
  late DateTime _startTime;
  bool _isSessionActive = false;
  int _durationMinutes = 30;
  final _nameController = TextEditingController(text: 'Focus Session');

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final sessions = ref.watch(focusSessionsProvider(userId ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Sessions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_isSessionActive)
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Start a Focus Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Session Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Duration (minutes)'),
                  const SizedBox(height: 8),
                  Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '$_durationMinutes min',
                    onChanged: (value) {
                      setState(() => _durationMinutes = value.toInt());
                    },
                  ),
                  Text(
                    'Selected: $_durationMinutes minutes',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Start Session',
                    onPressed: () {
                      setState(() {
                        _isSessionActive = true;
                        _startTime = DateTime.now();
                      });
                    },
                  ),
                ],
              ),
            )
          else
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<Duration>(
                    stream: _countdownStream(),
                    builder: (context, snapshot) {
                      final remaining =
                          snapshot.data ?? Duration(minutes: _durationMinutes);
                      return Column(
                        children: [
                          Text(
                            _formatDuration(remaining),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 360;
                              if (narrow) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: PrimaryButton(
                                        label: 'End Session',
                                        onPressed: () =>
                                            _endSession(userId!, false),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: SecondaryButton(
                                        label: 'Extend +10min',
                                        onPressed: () {
                                          setState(
                                              () => _durationMinutes += 10);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  PrimaryButton(
                                    label: 'End Session',
                                    onPressed: () =>
                                        _endSession(userId!, false),
                                  ),
                                  SecondaryButton(
                                    label: 'Extend +10min',
                                    onPressed: () {
                                      setState(() => _durationMinutes += 10);
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          const Text(
            'Recent Sessions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          sessions.when(
            data: (list) => Column(
              children: list.take(5).map((session) {
                return Card(
                  child: ListTile(
                    title: Text(session.sessionName),
                    subtitle: Text(
                      '${session.durationMinutes} min • +${session.pointsEarned} pts',
                    ),
                    trailing: session.completed
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.schedule),
                  ),
                );
              }).toList(),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Stream<Duration> _countdownStream() {
    return Stream.periodic(
      const Duration(seconds: 1),
      (count) {
        final elapsed = DateTime.now().difference(_startTime);
        final remaining = Duration(minutes: _durationMinutes) - elapsed;
        return remaining.isNegative ? Duration.zero : remaining;
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endSession(String userId, bool completed) async {
    final elapsed = DateTime.now().difference(_startTime);
    final pointsEarned = (elapsed.inMinutes ~/ 5) * 10;

    final session = FocusSession(
      id: '',
      userId: userId,
      sessionName: _nameController.text,
      durationMinutes: _durationMinutes,
      pointsEarned: pointsEarned,
      startedAt: _startTime,
      endedAt: DateTime.now(),
      completed: completed,
      notes: null,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(createFocusSessionProvider(session).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session saved! +$pointsEarned points'),
          ),
        );
      }
      setState(() {
        _isSessionActive = false;
        _nameController.clear();
        _durationMinutes = 30;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    }
  }
}
