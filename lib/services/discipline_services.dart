import 'auth_repository.dart';
import 'community_repository.dart';
import 'subscription_repository.dart';

class DisciplineServices {
  const DisciplineServices({
    required this.auth,
    required this.community,
    required this.subscription,
  });

  final AuthRepository auth;
  final CommunityRepository community;
  final SubscriptionRepository subscription;

  factory DisciplineServices.stub() {
    return DisciplineServices(
      auth: StubAuthRepository(),
      community: StubCommunityRepository(),
      subscription: StubSubscriptionRepository(),
    );
  }
}
