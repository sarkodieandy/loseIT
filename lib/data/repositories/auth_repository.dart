import 'package:supabase_flutter/supabase_flutter.dart';


class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<User?> signInAnonymously() async {
    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    return user;
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    return user;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    return user;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
