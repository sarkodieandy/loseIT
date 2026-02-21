import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/profile_repository.dart';

class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final ProfileRepository _repository;

  Future<void> load() async {
    if (!mounted) return;
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.fetchProfile();
      if (!mounted) return;
      state = AsyncValue.data(profile);
    } catch (error, stackTrace) {
      if (!mounted) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final updated = await _repository.upsertProfile(profile);
    if (mounted) {
      state = AsyncValue.data(updated);
    }
    return updated;
  }
}
