import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class AppAuthException implements Exception {
  final String message;
  final String? code;

  AppAuthException(this.message, [this.code]);

  @override
  String toString() => message;
}

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  String? get currentUserId => _client.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResult> signInAnonymously() async {
    AppLogger.info('🔐 [AUTH] signInAnonymously START');
    try {
      AppLogger.info('🔐 [AUTH] Calling _client.auth.signInAnonymously()...');
      final response = await _client.auth.signInAnonymously();
      AppLogger.info('🔐 [AUTH] signInAnonymously responded');
      AppLogger.info('🔐 [AUTH] response.user: ${response.user?.id}');
      AppLogger.info('🔐 [AUTH] response.session: ${response.session != null}');

      // Validate response
      if (response.user == null || response.session == null) {
        AppLogger.warn(
            '❌ [AUTH] signInAnonymously FAILED: user=${response.user == null}, session=${response.session == null}');
        throw AppAuthException(
          'Anonymous sign-in failed: Unable to create session',
          'NO_SESSION',
        );
      }

      AppLogger.info(
          '✅ [AUTH] signInAnonymously SUCCESS: userId=${response.user?.id}');
      AppLogger.info(
        'Auth signInAnonymously success userId=${response.user?.id} hasSession=${response.session != null}',
      );
      return AuthResult(user: response.user, session: response.session);
    } on AppAuthException catch (e) {
      AppLogger.warn(
          '❌ [AUTH] AppAuthException: ${e.message} (code: ${e.code})');
      rethrow;
    } on AuthApiException catch (e, stackTrace) {
      // Preserve AuthApiException so callers can handle specific error codes
      // (e.g. anonymous_provider_disabled).
      AppLogger.error('auth.signInAnonymously', e, stackTrace);
      rethrow;
    } on AuthException catch (error, stackTrace) {
      AppLogger.error('auth.signInAnonymously', error, stackTrace);
      throw AppAuthException(
        'Unable to sign in anonymously. Please check your connection and try again.',
        error.code ?? error.statusCode,
      );
    } catch (error, stackTrace) {
      AppLogger.error('auth.signInAnonymously', error, stackTrace);
      throw AppAuthException(
        'Unable to sign in anonymously. Please check your connection and try again.',
        error.toString(),
      );
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password) async {
    AppLogger.info('📧 [AUTH] signUpWithEmail START: email=$email');

    // Validate inputs
    if (email.trim().isEmpty) {
      AppLogger.warn('❌ [AUTH] Validation: Email is empty');
      throw AppAuthException('Email cannot be empty', 'EMPTY_EMAIL');
    }
    if (password.trim().isEmpty) {
      AppLogger.warn('❌ [AUTH] Validation: Password is empty');
      throw AppAuthException('Password cannot be empty', 'EMPTY_PASSWORD');
    }
    if (!_isValidEmail(email)) {
      AppLogger.warn('❌ [AUTH] Validation: Email format invalid: $email');
      throw AppAuthException(
          'Please enter a valid email address', 'INVALID_EMAIL');
    }
    if (password.length < 6) {
      AppLogger.warn(
          '❌ [AUTH] Validation: Password too short (${password.length} chars)');
      throw AppAuthException(
          'Password must be at least 6 characters', 'WEAK_PASSWORD');
    }

    AppLogger.info('✅ [AUTH] Validation passed for email=$email');
    try {
      AppLogger.info('📧 [AUTH] Calling _client.auth.signUp()...');
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('📧 [AUTH] signUp responded');
      AppLogger.info('📧 [AUTH] response.user: ${response.user?.id}');
      AppLogger.info('📧 [AUTH] response.session: ${response.session != null}');

      // Validate response
      if (response.user == null) {
        AppLogger.warn('❌ [AUTH] signUpWithEmail FAILED: No user returned');
        throw AppAuthException(
          'Sign-up failed: Unable to create user account',
          'NO_USER',
        );
      }

      // When "Confirm email" is enabled in Supabase, signUp succeeds but does not
      // return a session until the user confirms their email.
      final needsConfirmation = response.session == null;
      AppLogger.info(
          '✅ [AUTH] signUpWithEmail SUCCESS: userId=${response.user?.id}, needsConfirmation=$needsConfirmation');
      AppLogger.info(
        'Auth signUpWithEmail success userId=${response.user?.id} hasSession=${response.session != null} needsConfirmation=$needsConfirmation',
      );
      return AuthResult(
        user: response.user,
        session: response.session,
        needsEmailConfirmation: needsConfirmation,
      );
    } on AppAuthException catch (e) {
      AppLogger.warn(
          '❌ [AUTH] AppAuthException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
          '❌ [AUTH] signUpWithEmail EXCEPTION: $error', error, stackTrace);

      final message = _parseAuthError(error.toString());
      throw AppAuthException(
        message,
        error.toString(),
      );
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    AppLogger.info('📧 [AUTH] signInWithEmail START: email=$email');
    AppLogger.info('Auth signInWithEmail start email=$email');

    // Validate inputs
    if (email.trim().isEmpty) {
      AppLogger.warn('❌ [AUTH] Validation: Email is empty');
      throw AppAuthException('Email cannot be empty', 'EMPTY_EMAIL');
    }
    if (password.trim().isEmpty) {
      AppLogger.warn('❌ [AUTH] Validation: Password is empty');
      throw AppAuthException('Password cannot be empty', 'EMPTY_PASSWORD');
    }
    if (!_isValidEmail(email)) {
      AppLogger.warn('❌ [AUTH] Validation: Email format invalid: $email');
      throw AppAuthException(
          'Please enter a valid email address', 'INVALID_EMAIL');
    }

    AppLogger.info('✅ [AUTH] Validation passed for email=$email');
    try {
      AppLogger.info('📧 [AUTH] Calling _client.auth.signInWithPassword()...');
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('📧 [AUTH] signInWithPassword responded');
      AppLogger.info('📧 [AUTH] response.user: ${response.user?.id}');
      AppLogger.info('📧 [AUTH] response.session: ${response.session != null}');

      // Validate response
      if (response.user == null || response.session == null) {
        AppLogger.warn(
            '❌ [AUTH] signInWithEmail FAILED: user=${response.user == null}, session=${response.session == null}');
        throw AppAuthException(
          'Sign-in failed: Invalid email or password',
          'INVALID_CREDENTIALS',
        );
      }

      AppLogger.info(
          '✅ [AUTH] signInWithEmail SUCCESS: userId=${response.user?.id}');
      AppLogger.info(
        'Auth signInWithEmail success userId=${response.user?.id} hasSession=${response.session != null}',
      );
      return AuthResult(user: response.user, session: response.session);
    } on AppAuthException catch (e) {
      AppLogger.warn(
          '❌ [AUTH] AppAuthException: ${e.message} (code: ${e.code})');
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
          '❌ [AUTH] signInWithEmail EXCEPTION: $error', error, stackTrace);
      final message = _parseAuthError(error.toString());
      throw AppAuthException(
        message,
        error.toString(),
      );
    }
  }

  Future<void> signOut() async {
    AppLogger.info('Auth signOut');
    try {
      await _client.auth.signOut();
    } catch (error, stackTrace) {
      AppLogger.error('auth.signOut', error, stackTrace);
      throw AppAuthException(
        'Unable to sign out. Please try again.',
        error.toString(),
      );
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  /// Parse Supabase auth errors into user-friendly messages
  String _parseAuthError(String error) {
    if (error.contains('already registered')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('User already registered')) {
      return 'This email is already registered.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please confirm your email address first.';
    }
    if (error.contains('Invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (error.contains('Weak password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    return 'An authentication error occurred. Please try again.';
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
