import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/journal_entry.dart';
import '../data/repositories/journal_repository.dart';

class JournalController extends StateNotifier<AsyncValue<List<JournalEntry>>> {
  JournalController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final JournalRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final entries = await _repository.fetchEntries();
      state = AsyncValue.data(entries);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addEntry(JournalEntry entry) async {
    final current = state.value ?? const <JournalEntry>[];
    state = AsyncValue.data(<JournalEntry>[entry, ...current]);
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final current = state.value ?? const <JournalEntry>[];
    final updated = current
        .map((e) => e.id == entry.id ? entry : e)
        .toList(growable: false);
    state = AsyncValue.data(updated);
  }

  Future<void> removeEntry(String id) async {
    final current = state.value ?? const <JournalEntry>[];
    state = AsyncValue.data(
      current.where((e) => e.id != id).toList(growable: false),
    );
  }
}
