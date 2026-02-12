abstract class AuthRepository {
  Future<void> signInWithApple();
  Future<void> signInWithGoogle();
  Future<void> signInAnonymously();
  Future<void> signOut();
}

class StubAuthRepository implements AuthRepository {
  @override
  Future<void> signInWithApple() => Future.value();

  @override
  Future<void> signInWithGoogle() => Future.value();

  @override
  Future<void> signInAnonymously() => Future.value();

  @override
  Future<void> signOut() => Future.value();
}
