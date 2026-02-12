import 'package:flutter/cupertino.dart';

import '../../../core/navigation/discipline_page_route.dart';
import 'screens/biometric_setup_screen.dart';
import 'screens/email_sign_up_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sign_up_screen.dart';

class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key});

  static const signUp = '/';
  static const emailSignUp = '/email';
  static const login = '/login';
  static const biometric = '/biometric';

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
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
      initialRoute: AuthFlow.signUp,
      onGenerateRoute: (settings) {
        return switch (settings.name) {
          AuthFlow.signUp =>
            _route(const SignUpScreen(), name: AuthFlow.signUp),
          AuthFlow.emailSignUp =>
            _route(const EmailSignUpScreen(), name: AuthFlow.emailSignUp),
          AuthFlow.login => _route(const LoginScreen(), name: AuthFlow.login),
          AuthFlow.biometric => _route(
              const BiometricSetupScreen(),
              name: AuthFlow.biometric,
            ),
          _ => _route(const SignUpScreen(), name: AuthFlow.signUp),
        };
      },
    );
  }
}
