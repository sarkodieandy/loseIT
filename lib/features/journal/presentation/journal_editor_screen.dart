import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/user_habit.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/habit_selection_provider.dart';
import '../../../providers/repository_providers.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key});

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _contentController = TextEditingController();
  final _transcriptController = TextEditingController();
  final _recorder = AudioRecorder();
  final _speech = stt.SpeechToText();
  DateTime _entryDate = DateTime.now();
  String? _mood;
  File? _photo;
  File? _audio;
  bool _isRecording = false;
  bool _saving = false;

  @override
  void dispose() {
    _recorder.dispose();
    _contentController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _photo = File(image.path));
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      await _speech.stop();
      if (path != null) {
        setState(() {
          _audio = File(path);
          _isRecording = false;
        });
      } else {
        setState(() => _isRecording = false);
      }
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required.')),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/journal_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    final speechReady = await _speech.initialize();
    if (speechReady) {
      await _speech.listen(
        onResult: (result) {
          setState(() => _transcriptController.text = result.recognizedWords);
        },
      );
    }

    setState(() => _isRecording = true);
  }

  Future<void> _save() async {
    if (_saving) return;
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something.')),
      );
      return;
    }

    setState(() => _saving = true);

    final repo = ref.read(journalRepositoryProvider);
    final controller = ref.read(journalControllerProvider.notifier);
    final session = ref.read(sessionProvider);
    final selectedHabitId = ref.read(selectedHabitIdProvider);

    try {
      String? photoUrl;
      String? audioUrl;
      if (_photo != null && session?.user != null) {
        photoUrl = await repo.uploadPhoto(_photo!, userId: session!.user.id);
      }
      if (_audio != null && session?.user != null) {
        audioUrl = await repo.uploadAudio(_audio!, userId: session!.user.id);
      }

      final entry = await repo.createEntry(
        content: text,
        entryDate: _entryDate,
        habitId: selectedHabitId,
        mood: _mood,
        photoUrl: photoUrl,
        audioUrl: audioUrl,
        transcript: _transcriptController.text.trim().isEmpty
            ? null
            : _transcriptController.text.trim(),
      );
      await controller.addEntry(entry);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    final selectedHabitId = ref.watch(selectedHabitIdProvider);
    final habits = habitsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <UserHabit>[],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('New Entry')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          if (habits.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: selectedHabitId ?? habits.first.id,
              items: habits
                  .map(
                    (habit) => DropdownMenuItem<String>(
                      value: habit.id,
                      child: Text(habit.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(selectedHabitIdProvider.notifier).state = value;
                }
              },
              decoration: const InputDecoration(
                labelText: 'Habit',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: _entryDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (selected != null) {
                setState(() => _entryDate = selected);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text('${_entryDate.month}/${_entryDate.day}/${_entryDate.year}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'How are you feeling?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mood,
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem(value: 'happy', child: Text('Happy')),
              DropdownMenuItem(value: 'calm', child: Text('Calm')),
              DropdownMenuItem(value: 'anxious', child: Text('Anxious')),
              DropdownMenuItem(value: 'tired', child: Text('Tired')),
            ],
            onChanged: (value) => setState(() => _mood = value),
            decoration: const InputDecoration(
              labelText: 'Mood (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.photo),
            label: const Text('Attach photo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _toggleRecording,
            icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic),
            label: Text(_isRecording ? 'Stop recording' : 'Record voice note'),
          ),
          if (_photo != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _photo!,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (_audio != null) ...[
            const SizedBox(height: 12),
            Text(
              'Voice note ready',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _transcriptController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Transcription (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save Entry',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}
