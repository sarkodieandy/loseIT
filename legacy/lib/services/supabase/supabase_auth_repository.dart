import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth_repository.dart';
import 'profile_store.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._profiles);

  final SupabaseClient _client;
  final SupabaseProfileStore _profiles;

  @override
  bool get hasActiveSession =>
      _client.auth.currentSession != null || _client.auth.currentUser != null;

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Unable to create account right now.');
    }
    if (response.session == null) {
      throw const AuthException(
        'Email confirmation is enabled. Confirm your email, then log in.',
      );
    }

    await _profiles.ensureProfileForCurrentUser();
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw const AuthException('Unable to log in with these credentials.');
    }

    await _profiles.ensureProfileForCurrentUser();
  }

  @override
  Future<void> signInWithApple() async {
    final launched = await _client.auth.signInWithOAuth(OAuthProvider.apple);
    if (!launched) {
      throw const AuthException('Unable to start Apple sign-in.');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final launched = await _client.auth.signInWithOAuth(OAuthProvider.google);
    if (!launched) {
      throw const AuthException('Unable to start Google sign-in.');
    }
  }

  @override
  Future<void> signInAnonymously() async {
    final response = await _client.auth.signInAnonymously();
    if (response.user == null) {
      throw const AuthException('Unable to create anonymous session.');
    }
    await _profiles.ensureProfileForCurrentUser();
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<String> currentAlias() => _profiles.aliasForCurrentUser();
}
