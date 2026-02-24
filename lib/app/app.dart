import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../providers/premium_controller.dart'; // for PremiumStatus type
import '../providers/notification_providers.dart';
import 'router.dart';

class BeSoberApp extends ConsumerStatefulWidget {
  const BeSoberApp({super.key});

  @override
  ConsumerState<BeSoberApp> createState() => _BeSoberAppState();
}

class _BeSoberAppState extends ConsumerState<BeSoberApp> {
  @override
  void initState() {
    super.initState();
    // all provider interactions have been moved into build() where the
    // element tree (including ProviderScope) is guaranteed to exist. This
    // avoids assertions about calling ref.listen outside of a build method and
    // prevents the "deactivated widget's ancestor" error seen when the
    // post-frame callback fired before the scope was attached.
  }

  @override
  Widget build(BuildContext context) {
    // kick off notification initialization whenever the widget builds; the
    // FutureProvider caches the work so this is effectively a no-op after the
    // first call.
    ref.read(initializeNotificationsProvider);

    // monitor premium status changes; placing the listener here satisfies
    // Riverpod's debug assertion and is safe even if build is invoked.
    ref.listen<PremiumStatus?>(premiumControllerProvider, (prev, next) {
      // only navigate if user is signed in and onboarding is complete
      final session = ref.read(sessionProvider);
      final onboardingComplete = ref.read(onboardingCompleteProvider);
      if (session != null &&
          onboardingComplete &&
          !(next?.hasAccess ?? false)) {
        final router = ref.read(routerProvider);
        // defer navigation to end of frame just in case we're mid-build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.go('/paywall');
        });
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
