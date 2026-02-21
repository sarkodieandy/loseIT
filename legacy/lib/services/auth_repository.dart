abstract class AuthRepository {
  bool get hasActiveSession;
  String? get currentUserId;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });
  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<void> signOut();
  Future<String> currentAlias();
}

class StubAuthRepository implements AuthRepository {
  @override
  bool get hasActiveSession => false;

  @override
  String? get currentUserId => null;

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) =>
      Future.value();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) =>
      Future.value();

  @override
  Future<void> signInWithApple() => Future.value();

  @override
  Future<void> signInWithGoogle() => Future.value();

  @override
  Future<void> signInAnonymously() => Future.value();

  @override
  Future<void> signOut() => Future.value();

  @override
  Future<String> currentAlias() async => 'Guest';
}
