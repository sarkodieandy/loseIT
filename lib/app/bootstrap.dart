import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_logger.dart';
import '../data/services/local_cache_service.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');
    await Hive.initFlutter();
    await LocalCacheService.instance.initialize();

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
        'https://inixrkdcipviqofuhgon.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluaXhya2RjaXB2aXFvZnVoZ29uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTM0MTQsImV4cCI6MjA4NjQ4OTQxNH0.z3yVekj9rvcOW-SZSKC0cSQEkmh7roqq6T45SuPE6_4';
    if (dotenv.env['SUPABASE_URL'] == null ||
        dotenv.env['SUPABASE_ANON_KEY'] == null) {
      AppLogger.warn('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session?.user != null) {
        AppLogger.info('Auth session updated for user ${session!.user.id}');
      }
    });
  }
}
