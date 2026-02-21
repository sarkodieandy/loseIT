class SubscriptionVerificationResult {
  const SubscriptionVerificationResult({
    required this.isPremium,
    required this.status,
    this.expiresAt,
    this.message,
  });

  final bool isPremium;
  final String status;
  final DateTime? expiresAt;
  final String? message;
}

abstract class SubscriptionRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool value);
  Future<SubscriptionVerificationResult> verifyAppleSubscription({
    required String productId,
    required String verificationData,
    String? transactionId,
  });
}

class StubSubscriptionRepository implements SubscriptionRepository {
  bool _premium = false;

  @override
  Future<bool> isPremium() async => _premium;

  @override
  Future<void> setPremium(bool value) async {
    _premium = value;
  }

  @override
  Future<SubscriptionVerificationResult> verifyAppleSubscription({
    required String productId,
    required String verificationData,
    String? transactionId,
  }) async {
    _premium = true;
    return SubscriptionVerificationResult(
      isPremium: true,
      status: 'active',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 365)),
      message: 'Stub purchase verification succeeded.',
    );
  }
}
