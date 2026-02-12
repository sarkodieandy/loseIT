import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/fade_in.dart';
import '../widgets/paywall_plan_card.dart';

enum PaywallPlan { monthly, yearly }

class PremiumPaywallScreen extends StatefulWidget {
  const PremiumPaywallScreen({super.key});

  @override
  State<PremiumPaywallScreen> createState() => _PremiumPaywallScreenState();
}

class _PremiumPaywallScreenState extends State<PremiumPaywallScreen> {
  PaywallPlan _selected = PaywallPlan.yearly;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    Widget feature(String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              CupertinoIcons.checkmark_seal,
              size: 18,
              color: DisciplineColors.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: DisciplineTextStyles.secondary),
            ),
          ],
        ),
      );
    }

    return DisciplineScaffold(
      title: 'Discipline Premium',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          const FadeIn(
            child: Center(
              child: ProgressRing(
                progress: 0.84,
                size: 138,
                strokeWidth: 10,
                child: _PaywallRingCenter(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const FadeIn(
            delay: Duration(milliseconds: 80),
            child: Text('Upgrade Your Discipline.',
                style: DisciplineTextStyles.title),
          ),
          const SizedBox(height: 10),
          FadeIn(
            delay: const Duration(milliseconds: 120),
            child: Text(
              'Subscription-first protection built for privacy and performance.',
              style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Included', style: DisciplineTextStyles.caption),
                const SizedBox(height: 12),
                feature('AI Relapse Prediction'),
                feature('Unlimited Emergency Support'),
                feature('Lock Mode Protection'),
                feature('Advanced Analytics'),
                feature('Anonymous Community Access'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaywallPlanCard(
            title: 'Monthly',
            subtitle: 'Billed monthly, cancel anytime.',
            price: '\$9.99',
            selected: _selected == PaywallPlan.monthly,
            onTap: () => setState(() => _selected = PaywallPlan.monthly),
          ),
          const SizedBox(height: 12),
          PaywallPlanCard(
            title: 'Yearly',
            subtitle: 'Best long-term value.',
            badge: 'Best Value',
            price: '\$59.99',
            selected: _selected == PaywallPlan.yearly,
            onTap: () => setState(() => _selected = PaywallPlan.yearly),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Start 7-Day Free Trial',
            onPressed: () {
              app.completeOnboarding(isPremium: true);
            },
          ),
          const SizedBox(height: 10),
          Center(
            child: DisciplineTextButton(
              label: 'Not now',
              onPressed: () {
                app.completeOnboarding(isPremium: false);
              },
              color: DisciplineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Trial auto-renews. Cancel anytime in Settings.',
              style: DisciplineTextStyles.caption.copyWith(
                color: DisciplineColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _PaywallRingCenter extends StatelessWidget {
  const _PaywallRingCenter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '12',
          style: DisciplineTextStyles.streakNumber.copyWith(fontSize: 40),
        ),
        const SizedBox(height: 2),
        Text(
          'day streak',
          style: DisciplineTextStyles.caption.copyWith(
            color: DisciplineColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
