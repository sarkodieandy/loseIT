import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/widgets/section_card.dart';
import '../../../data/models/recovery_plan.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/repository_providers.dart';

class RecoveryPlanScreen extends ConsumerStatefulWidget {
  const RecoveryPlanScreen({super.key});

  @override
  ConsumerState<RecoveryPlanScreen> createState() => _RecoveryPlanScreenState();
}

class _RecoveryPlanScreenState extends ConsumerState<RecoveryPlanScreen> {
  static const String _defaultSupportMessage =
      'Hey — I\'m having a strong urge right now. Can you talk for a minute?';

  final TextEditingController _triggerController = TextEditingController();
  final TextEditingController _warningController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  final TextEditingController _supportMessageController =
      TextEditingController();

  bool _hydrated = false;
  bool _saving = false;

  List<String> _triggers = <String>[];
  List<String> _warningSigns = <String>[];
  List<String> _copingActions = <String>[];

  @override
  void dispose() {
    _triggerController.dispose();
    _warningController.dispose();
    _actionController.dispose();
    _supportMessageController.dispose();
    super.dispose();
  }

  void _hydrate(RecoveryPlan? plan) {
    if (_hydrated || !mounted) return;
    setState(() {
      _triggers = List<String>.from(plan?.triggers ?? const <String>[]);
      _warningSigns =
          List<String>.from(plan?.warningSigns ?? const <String>[]);
      _copingActions =
          List<String>.from(plan?.copingActions ?? const <String>[]);
      _supportMessageController.text =
          (plan?.supportMessage?.trim().isNotEmpty == true)
              ? plan!.supportMessage!.trim()
              : _defaultSupportMessage;
      _hydrated = true;
    });
  }

  void _addItem({
    required TextEditingController controller,
    required List<String> list,
    required void Function(List<String>) assign,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    final exists = list.any((e) => e.toLowerCase() == value.toLowerCase());
    if (exists) {
      controller.clear();
      return;
    }
    assign(<String>[...list, value]);
    controller.clear();
  }

  Future<void> _save() async {
    if (_saving) return;
    final session = ref.read(sessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save your plan.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(recoveryPlanRepositoryProvider).upsertPlan(
            triggers: _triggers,
            warningSigns: _warningSigns,
            copingActions: _copingActions,
            supportMessage: _supportMessageController.text.trim(),
          );

      ref.invalidate(recoveryPlanProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovery plan saved.')),
      );
      context.pop();
    } catch (error, stackTrace) {
      AppLogger.error('recovery_plan.save', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('relation \"public.recovery_plans\"') ||
        message.contains('recovery_plans')) {
      return 'Recovery plan backend is not set up yet.\n\nRun `supabase/schema.sql` in Supabase SQL Editor to create `recovery_plans`.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(recoveryPlanProvider);

    ref.listen<AsyncValue<RecoveryPlan?>>(recoveryPlanProvider, (_, next) {
      if (!_hydrated && next is AsyncData<RecoveryPlan?>) {
        _hydrate(next.value);
      }
    });

    final session = ref.watch(sessionProvider);

    final loading = planAsync.isLoading && !_hydrated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recovery Plan'),
        actions: <Widget>[
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                const SectionCard(
                  child: Text(
                    'This plan is for high‑risk moments. Keep it short, personal, and actionable — so you can follow it even when you\'re stressed.',
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                if (session == null)
                  const SectionCard(
                    child: Text('Sign in to save and sync your plan.'),
                  ),
                if (planAsync.hasError)
                  SectionCard(
                    child: Text(_friendlyError(planAsync.error!)),
                  ),
                const SizedBox(height: 16),
                _ChipEditorCard(
                  title: 'Top triggers',
                  subtitle:
                      'Examples: boredom, late‑night scrolling, stress, loneliness',
                  items: _triggers,
                  controller: _triggerController,
                  hintText: 'Add a trigger',
                  onAdd: () => setState(() {
                    _addItem(
                      controller: _triggerController,
                      list: _triggers,
                      assign: (v) => _triggers = v,
                    );
                  }),
                  onRemove: (value) =>
                      setState(() => _triggers.remove(value)),
                ),
                const SizedBox(height: 12),
                _ChipEditorCard(
                  title: 'Early warning signs',
                  subtitle:
                      'Examples: hiding, rationalizing, skipping sleep, isolating',
                  items: _warningSigns,
                  controller: _warningController,
                  hintText: 'Add a warning sign',
                  onAdd: () => setState(() {
                    _addItem(
                      controller: _warningController,
                      list: _warningSigns,
                      assign: (v) => _warningSigns = v,
                    );
                  }),
                  onRemove: (value) =>
                      setState(() => _warningSigns.remove(value)),
                ),
                const SizedBox(height: 12),
                _ChipEditorCard(
                  title: 'My go‑to actions',
                  subtitle:
                      'Examples: 3‑minute grounding, urge timer, shower, walk outside',
                  items: _copingActions,
                  controller: _actionController,
                  hintText: 'Add an action',
                  onAdd: () => setState(() {
                    _addItem(
                      controller: _actionController,
                      list: _copingActions,
                      assign: (v) => _copingActions = v,
                    );
                  }),
                  onRemove: (value) =>
                      setState(() => _copingActions.remove(value)),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Support message',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A short message you can copy/paste in SOS mode.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _supportMessageController,
                        minLines: 2,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: _defaultSupportMessage,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: <Widget>[
                          OutlinedButton.icon(
                            onPressed: () {
                              _supportMessageController.text =
                                  _defaultSupportMessage;
                            },
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Reset'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final text =
                                  _supportMessageController.text.trim();
                              if (text.isEmpty) return;
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied.')),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed:
                        session == null || _saving ? null : () => _save(),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save plan'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tip: keep your actions concrete and fast. “Start urge timer” beats “be strong.”',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _ChipEditorCard extends StatelessWidget {
  const _ChipEditorCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.controller,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final TextEditingController controller;
  final String hintText;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (items.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => InputChip(
                      label: Text(item),
                      onDeleted: () => onRemove(item),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onAdd,
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
