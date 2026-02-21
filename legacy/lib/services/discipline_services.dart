import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_logger.dart';
import 'app_state_repository.dart';
import 'auth_repository.dart';
import 'community_repository.dart';
import 'supabase/profile_store.dart';
import 'supabase/supabase_app_state_repository.dart';
import 'supabase/supabase_auth_repository.dart';
import 'supabase/supabase_bootstrap.dart';
import 'supabase/supabase_community_repository.dart';
import 'supabase/supabase_subscription_repository.dart';
import 'subscription_repository.dart';

class DisciplineServices {
  const DisciplineServices({
    required this.appState,
    required this.auth,
    required this.community,
    required this.subscription,
  });

  final AppStateRepository appState;
  final AuthRepository auth;
  final CommunityRepository community;
  final SubscriptionRepository subscription;

  factory DisciplineServices.stub() {
    return DisciplineServices(
      appState: StubAppStateRepository(),
      auth: StubAuthRepository(),
      community: StubCommunityRepository(),
      subscription: StubSubscriptionRepository(),
    );
  }

  factory DisciplineServices.supabase(SupabaseClient client) {
    final profiles = SupabaseProfileStore(client);
    return DisciplineServices(
      appState: SupabaseAppStateRepository(client),
      auth: SupabaseAuthRepository(client, profiles),
      community: SupabaseCommunityRepository(client, profiles),
      subscription: SupabaseSubscriptionRepository(client, profiles),
    );
  }

  static Future<DisciplineServices> bootstrap({
    bool fallbackToStub = false,
  }) async {
    try {
      final client = await SupabaseBootstrap.initialize();
      return DisciplineServices.supabase(client);
    } catch (error, stackTrace) {
      AppLogger.error('DisciplineServices.bootstrap', error, stackTrace);
      if (!fallbackToStub) rethrow;
      return DisciplineServices.stub();
    }
  }
}
