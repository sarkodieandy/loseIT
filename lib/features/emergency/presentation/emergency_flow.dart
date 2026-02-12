import 'package:flutter/cupertino.dart';

import '../../../core/navigation/discipline_page_route.dart';
import 'screens/ai_intervention_screen.dart';
import 'screens/breathing_screen.dart';
import 'screens/emergency_start_screen.dart';
import 'screens/quick_challenge_screen.dart';
import 'screens/reflection_screen.dart';

class EmergencyFlow extends StatefulWidget {
  const EmergencyFlow({super.key, this.onExit, this.showClose = false});

  final VoidCallback? onExit;
  final bool showClose;

  static const start = '/';
  static const breathing = '/breathing';
  static const intervention = '/intervention';
  static const challenge = '/challenge';
  static const reflection = '/reflection';

  @override
  State<EmergencyFlow> createState() => _EmergencyFlowState();
}

class _EmergencyFlowState extends State<EmergencyFlow> {
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
      initialRoute: EmergencyFlow.start,
      onGenerateRoute: (settings) {
        final showClose = widget.showClose;
        final onExit = widget.onExit;

        return switch (settings.name) {
          EmergencyFlow.start => _route(
              EmergencyStartScreen(showClose: showClose, onExit: onExit),
              name: EmergencyFlow.start,
            ),
          EmergencyFlow.breathing => _route(
              BreathingScreen(showClose: showClose, onExit: onExit),
              name: EmergencyFlow.breathing,
            ),
          EmergencyFlow.intervention => _route(
              AiInterventionScreen(showClose: showClose, onExit: onExit),
              name: EmergencyFlow.intervention,
            ),
          EmergencyFlow.challenge => _route(
              QuickChallengeScreen(showClose: showClose, onExit: onExit),
              name: EmergencyFlow.challenge,
            ),
          EmergencyFlow.reflection => _route(
              ReflectionScreen(showClose: showClose, onExit: onExit),
              name: EmergencyFlow.reflection,
            ),
          _ => _route(
              EmergencyStartScreen(showClose: showClose, onExit: onExit),
              name: EmergencyFlow.start,
            ),
        };
      },
    );
  }
}
