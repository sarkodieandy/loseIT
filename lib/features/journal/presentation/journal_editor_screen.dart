import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_buttons.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class JournalEditorScreen extends ConsumerStatefulWidget {
  const JournalEditorScreen({super.key});

  @override
  ConsumerState<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends ConsumerState<JournalEditorScreen> {
  final _contentController = TextEditingController();
  DateTime _entryDate = DateTime.now();
  String? _mood;
  File? _photo;
  bool _saving = false;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _photo = File(image.path));
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

    try {
      String? photoUrl;
      if (_photo != null && session?.user != null) {
        photoUrl = await repo.uploadPhoto(_photo!, userId: session!.user.id);
      }

      final entry = await repo.createEntry(
        content: text,
        entryDate: _entryDate,
        mood: _mood,
        photoUrl: photoUrl,
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
    return Scaffold(
      appBar: AppBar(title: const Text('New Entry')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
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
