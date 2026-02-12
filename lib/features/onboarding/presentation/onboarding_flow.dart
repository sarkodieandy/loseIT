import 'package:flutter/cupertino.dart';

import '../../../core/navigation/discipline_page_route.dart';
import 'screens/addiction_selection_screen.dart';
import 'screens/ai_prediction_reveal_screen.dart';
import 'screens/frequency_severity_screen.dart';
import 'screens/high_risk_time_screen.dart';
import 'screens/premium_paywall_screen.dart';
import 'screens/trigger_identification_screen.dart';
import 'screens/welcome_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  static const welcome = '/';
  static const addiction = '/addiction';
  static const severity = '/severity';
  static const triggers = '/triggers';
  static const riskTime = '/risk-time';
  static const prediction = '/prediction';
  static const paywall = '/paywall';

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _navKey = GlobalKey<NavigatorState>();

  Route<void> _route(Widget page, {String? name}) {
    return DisciplinePageRoute<void>(
      settings: RouteSettings(name: name),
      builder: (_) => page,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navKey,
      initialRoute: OnboardingFlow.welcome,
      onGenerateRoute: (settings) {
        return switch (settings.name) {
          OnboardingFlow.welcome => _route(
              const WelcomeScreen(),
              name: OnboardingFlow.welcome,
            ),
          OnboardingFlow.addiction => _route(
              const AddictionSelectionScreen(),
              name: OnboardingFlow.addiction,
            ),
          OnboardingFlow.severity => _route(
              const FrequencySeverityScreen(),
              name: OnboardingFlow.severity,
            ),
          OnboardingFlow.triggers => _route(
              const TriggerIdentificationScreen(),
              name: OnboardingFlow.triggers,
            ),
          OnboardingFlow.riskTime => _route(
              const HighRiskTimeScreen(),
              name: OnboardingFlow.riskTime,
            ),
          OnboardingFlow.prediction => _route(
              const AiPredictionRevealScreen(),
              name: OnboardingFlow.prediction,
            ),
          OnboardingFlow.paywall => _route(
              const PremiumPaywallScreen(),
              name: OnboardingFlow.paywall,
            ),
          _ => _route(const WelcomeScreen(), name: OnboardingFlow.welcome),
        };
      },
    );
  }
}
