import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseBootstrap {
  static bool _initialized = false;

  static Future<SupabaseClient> initialize() async {
    if (!_initialized) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
    }
    return Supabase.instance.client;
  }
}
