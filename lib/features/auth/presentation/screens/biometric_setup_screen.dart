import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class BiometricSetupScreen extends StatelessWidget {
  const BiometricSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return DisciplineScaffold(
      title: 'Face ID',
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          const SizedBox(height: 28),
          const Icon(
            CupertinoIcons.lock_shield,
            size: 56,
            color: DisciplineColors.accent,
          ),
          const SizedBox(height: 16),
          const Text('Secure access.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Use Face ID to keep your Discipline system private.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Recommended', style: DisciplineTextStyles.caption),
                const SizedBox(height: 10),
                Text(
                  'Protects sensitive analytics, relapse predictions, and emergency logs.',
                  style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
                ),
              ],
            ),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Enable Face ID',
            onPressed: () => app.completeAuth(biometricEnabled: true),
          ),
          const SizedBox(height: 12),
          DisciplineButton(
            label: 'Not now',
            variant: DisciplineButtonVariant.secondary,
            onPressed: () => app.completeAuth(biometricEnabled: false),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
