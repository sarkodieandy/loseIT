import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../providers/repository_providers.dart';

class RelapseScreen extends ConsumerStatefulWidget {
  const RelapseScreen({super.key});

  @override
  ConsumerState<RelapseScreen> createState() => _RelapseScreenState();
}

class _RelapseScreenState extends ConsumerState<RelapseScreen> {
  DateTime _relapseDate = DateTime.now();
  final _noteController = TextEditingController();
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(relapseRepositoryProvider).createLog(
            relapseDate: _relapseDate,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      AppLogger.error('relapse.create', error, stackTrace);
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
      appBar: AppBar(title: const Text('Log relapse')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Logging a relapse is private and doesn’t reset your counter automatically.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _relapseDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _relapseDate = date);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text('${_relapseDate.month}/${_relapseDate.day}/${_relapseDate.year}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Save',
            onPressed: _saving ? null : _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}
