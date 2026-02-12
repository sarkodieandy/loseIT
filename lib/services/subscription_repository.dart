abstract class SubscriptionRepository {
  Future<bool> isPremium();
  Future<void> setPremium(bool value);
}

class StubSubscriptionRepository implements SubscriptionRepository {
  bool _premium = false;

  @override
  Future<bool> isPremium() async => _premium;

  @override
  Future<void> setPremium(bool value) async {
    _premium = value;
  }
}
