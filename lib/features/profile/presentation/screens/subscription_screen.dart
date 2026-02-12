import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final premium = app.state.isPremium;

        Widget planCard({
          required String title,
          required String price,
          required List<String> features,
          required bool highlighted,
          String? badge,
        }) {
          return DisciplineCard(
            borderColor: highlighted ? DisciplineColors.accent : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(title, style: DisciplineTextStyles.section),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              DisciplineColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color:
                                DisciplineColors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: DisciplineTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                    color: highlighted
                        ? DisciplineColors.accent
                        : DisciplineColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.checkmark,
                          size: 16,
                          color: highlighted
                              ? DisciplineColors.accent
                              : DisciplineColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child:
                                Text(f, style: DisciplineTextStyles.secondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return DisciplineScaffold(
          title: 'Subscription',
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            children: <Widget>[
              const Text('Plan control.', style: DisciplineTextStyles.title),
              const SizedBox(height: 10),
              Text(
                'Upgrade for relapse prediction, advanced analytics, and private chat.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 18),
              planCard(
                title: 'Standard',
                price: '\$0',
                highlighted: false,
                features: const <String>[
                  'Dashboard',
                  'Emergency flow',
                  'Basic analytics',
                ],
              ),
              const SizedBox(height: 14),
              planCard(
                title: 'Premium',
                price: '\$59.99 / year',
                badge: 'Best Value',
                highlighted: true,
                features: const <String>[
                  'AI relapse prediction',
                  'Unlimited emergency support',
                  'Lock Mode protection',
                  'Advanced analytics',
                  'Anonymous private chat',
                ],
              ),
              const SizedBox(height: 18),
              DisciplineButton(
                label: premium ? 'Premium Active' : 'Upgrade to Premium',
                onPressed: premium ? null : () => app.setPremium(true),
              ),
              const SizedBox(height: 12),
              if (premium)
                DisciplineButton(
                  label: 'Manage subscription',
                  variant: DisciplineButtonVariant.secondary,
                  onPressed: () {
                    showCupertinoDialog<void>(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text('Manage subscription'),
                        content:
                            const Text('Connect App Store billing here later.'),
                        actions: <CupertinoDialogAction>[
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
