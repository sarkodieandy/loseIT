import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResult> signInAnonymously() async {
    AppLogger.info('Auth signInAnonymously start');
    try {
      final response = await _client.auth.signInAnonymously();
      AppLogger.info(
        'Auth signInAnonymously success userId=${response.user?.id} hasSession=${response.session != null}',
      );
      return AuthResult(user: response.user, session: response.session);
    } catch (error, stackTrace) {
      AppLogger.error('auth.signInAnonymously', error, stackTrace);
      rethrow;
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password) async {
    AppLogger.info('Auth signUpWithEmail start email=$email');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // When "Confirm email" is enabled in Supabase, signUp succeeds but does not
      // return a session until the user confirms their email.
      final needsConfirmation = response.session == null;
      AppLogger.info(
        'Auth signUpWithEmail success userId=${response.user?.id} hasSession=${response.session != null} needsConfirmation=$needsConfirmation',
      );
      return AuthResult(
        user: response.user,
        session: response.session,
        needsEmailConfirmation: needsConfirmation,
      );
    } catch (error, stackTrace) {
      AppLogger.error('auth.signUpWithEmail', error, stackTrace);
      rethrow;
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    AppLogger.info('Auth signInWithEmail start email=$email');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.info(
        'Auth signInWithEmail success userId=${response.user?.id} hasSession=${response.session != null}',
      );
      return AuthResult(user: response.user, session: response.session);
    } catch (error, stackTrace) {
      AppLogger.error('auth.signInWithEmail', error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    AppLogger.info('Auth signOut');
    await _client.auth.signOut();
  }
}

class AuthResult {
  const AuthResult({
    required this.user,
    required this.session,
    this.needsEmailConfirmation = false,
  });

  final User? user;
  final Session? session;
  final bool needsEmailConfirmation;
}
