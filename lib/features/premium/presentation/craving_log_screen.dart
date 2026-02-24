import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/craving_log.dart';
import '../../../providers/accountability_providers.dart';
import '../../../providers/app_providers.dart';

class CravingLogScreen extends ConsumerStatefulWidget {
  const CravingLogScreen({super.key});

  @override
  ConsumerState<CravingLogScreen> createState() => _CravingLogScreenState();
}

class _CravingLogScreenState extends ConsumerState<CravingLogScreen> {
  int _intensity = 5;
  String? _selectedTrigger;
  String? _selectedStrategy;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final cravingLogs = ref.watch(cravingLogsProvider(userId ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Craving Log')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How intense is your craving?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(10, (i) {
                    final intensity = i + 1;
                    final selected = _intensity == intensity;
                    return GestureDetector(
                      onTap: () => setState(() => _intensity = intensity),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.red : Colors.grey[300],
                        ),
                        child: Center(
                          child: Text(
                            intensity.toString(),
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What triggered this craving?',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Stress',
                    'Social',
                    'Boredom',
                    'Emotion',
                    'Environment',
                  ]
                      .map((trigger) => FilterChip(
                            label: Text(trigger),
                            selected: _selectedTrigger == trigger,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTrigger = selected ? trigger : null;
                              });
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coping Strategy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'What did you do to manage this craving?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    _selectedStrategy = value;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Additional notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Log Craving',
            onPressed: () => _logCraving(userId!),
          ),
          const SizedBox(height: 32),
          if (cravingLogs.when(
            data: (logs) => logs.isNotEmpty,
            loading: () => false,
            error: (_, __) => false,
          ))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Cravings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                cravingLogs.when(
                  data: (logs) => Column(
                    children: logs.take(5).map((log) {
                      return Card(
                        child: ListTile(
                          title: Text('Intensity: ${log.intensity}/10'),
                          subtitle: Text(
                            log.trigger ?? 'No trigger noted',
                          ),
                          trailing: log.wasSuccessful == true
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error: $error'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _logCraving(String userId) async {
    final craving = CravingLog(
      id: '',
      userId: userId,
      habitId: null,
      intensity: _intensity,
      trigger: _selectedTrigger,
      copingStrategyUsed: _selectedStrategy,
      wasSuccessful: null,
      durationMinutes: null,
      notes: _noteController.text.isNotEmpty ? _noteController.text : null,
      loggedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(logCravingProvider(craving).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Craving logged successfully!')),
        );
        _resetForm();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging craving: $e')),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _intensity = 5;
      _selectedTrigger = null;
      _selectedStrategy = null;
      _noteController.clear();
    });
  }
}
