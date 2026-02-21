import 'package:flutter/cupertino.dart';

import '../features/auth/presentation/auth_flow.dart';
import '../features/onboarding/presentation/onboarding_flow.dart';
import '../navigation/main_tabs.dart';
import 'app_controller.dart';

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isHydrating) {
          return const CupertinoPageScaffold(
            child: Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
          );
        }

        final state = controller.state;

        if (!state.onboardingComplete) {
          return const OnboardingFlow();
        }

        if (!state.isAuthenticated) {
          return const AuthFlow();
        }

        return const MainTabs();
      },
    );
  }
}
