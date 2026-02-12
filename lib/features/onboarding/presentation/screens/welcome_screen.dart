import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../core/widgets/fade_in.dart';
import '../onboarding_flow.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DisciplineScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          const Spacer(flex: 3),
          const FadeIn(
            child: Text(
              'Take Back Control.',
              style: DisciplineTextStyles.headline,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),
          const FadeIn(
            delay: Duration(milliseconds: 90),
            child: Text(
              'Private. Intelligent. Built for Discipline.',
              style: DisciplineTextStyles.secondary,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 4),
          FadeIn(
            delay: const Duration(milliseconds: 160),
            child: DisciplineButton(
              label: 'Begin',
              onPressed: () {
                Navigator.of(context).pushNamed(OnboardingFlow.addiction);
              },
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
