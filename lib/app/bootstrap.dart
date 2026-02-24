import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/app_logger.dart';
import '../core/services/notification_service.dart';
import '../data/services/local_cache_service.dart';
import '../data/services/revenuecat_service.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.info('Bootstrap: loading .env');
    await dotenv.load(fileName: '.env');
    AppLogger.info('Bootstrap: init Hive');
    await Hive.initFlutter();
    AppLogger.info('Bootstrap: init local cache');
    await LocalCacheService.instance.initialize();

    final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
        'https://inixrkdcipviqofuhgon.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluaXhya2RjaXB2aXFvZnVoZ29uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTM0MTQsImV4cCI6MjA4NjQ4OTQxNH0.z3yVekj9rvcOW-SZSKC0cSQEkmh7roqq6T45SuPE6_4';
    if (dotenv.env['SUPABASE_URL'] == null ||
        dotenv.env['SUPABASE_ANON_KEY'] == null) {
      AppLogger.warn('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
    }

    AppLogger.info('Bootstrap: initializing Supabase');
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    // Log device platform for debugging RevenueCat setup
    final platform = Platform.isIOS
        ? 'iOS'
        : Platform.isAndroid
            ? 'Android'
            : 'Unknown';
    AppLogger.info('Bootstrap: platform=$platform');

    final revenueCatKey = dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
    if (revenueCatKey.trim().isEmpty) {
      AppLogger.warn(
          'Missing REVENUECAT_IOS_API_KEY in .env (premium disabled)');
    } else {
      final masked = revenueCatKey.length > 8
          ? '${revenueCatKey.substring(0, 4)}...${revenueCatKey.substring(revenueCatKey.length - 4)}'
          : '***';
      AppLogger.info('Bootstrap: RevenueCat key=$masked, platform=$platform');
      await RevenueCatService.instance.initialize(
        apiKey: revenueCatKey,
        entitlementId: dotenv.env['REVENUECAT_ENTITLEMENT_ID'] ?? 'premium',
      );
      final entitlementId =
          dotenv.env['REVENUECAT_ENTITLEMENT_ID'] ?? 'premium';
      AppLogger.info(
          'Bootstrap: RevenueCat ready, entitlement=$entitlementId, offering=default');
      RevenueCatService.instance
          .syncUser(Supabase.instance.client.auth.currentUser?.id);
    }

    AppLogger.info('Bootstrap: initializing notifications');
    final supabaseClient = Supabase.instance.client;
    await NotificationService().initialize(supabaseClient);
    AppLogger.info('Bootstrap: done');

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session?.user != null) {
        AppLogger.info('Auth session updated for user ${session!.user.id}');
      } else {
        AppLogger.info('Auth session cleared');
      }
      RevenueCatService.instance.syncUser(session?.user.id);
    });
  }
}
