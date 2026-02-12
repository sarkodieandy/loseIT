import 'package:flutter/cupertino.dart';

import '../../../app/app_controller.dart';
import '../../../core/navigation/discipline_page_route.dart';
import '../../../core/theme/discipline_colors.dart';
import '../../../core/theme/discipline_text_styles.dart';
import '../../../core/theme/theme_preference.dart';
import '../../../core/widgets/discipline_button.dart';
import '../../../core/widgets/discipline_card.dart';
import '../../../core/widgets/discipline_scaffold.dart';
import '../../../core/widgets/progress_ring.dart';
import 'screens/lock_mode_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'screens/subscription_screen.dart';

class ProfileHomeScreen extends StatelessWidget {
  const ProfileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final state = app.state;

        Widget row({
          required String title,
          required String subtitle,
          required IconData icon,
          required VoidCallback onTap,
        }) {
          return DisciplineCard(
            shadow: false,
            onTap: onTap,
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DisciplineColors.surface2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DisciplineColors.border.withValues(alpha: 0.75),
                    ),
                  ),
                  child: Icon(icon, color: DisciplineColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, style: DisciplineTextStyles.section),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: DisciplineTextStyles.caption.copyWith(
                          color: DisciplineColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 18,
                  color: DisciplineColors.textTertiary,
                ),
              ],
            ),
          );
        }

        String themeLabel(ThemePreference preference) {
          return switch (preference) {
            ThemePreference.system => 'System',
            ThemePreference.light => 'Light',
            ThemePreference.dark => 'Dark',
          };
        }

        return DisciplineScaffold(
          title: 'Profile',
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            children: <Widget>[
              const Text('System overview.', style: DisciplineTextStyles.title),
              const SizedBox(height: 10),
              Text(
                'Private performance controls and protection settings.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 18),
              DisciplineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.moon_stars,
                          color: DisciplineColors.accent,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Appearance',
                          style: DisciplineTextStyles.section.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          themeLabel(state.themePreference),
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Follow system theme or choose a fixed mode.',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CupertinoSlidingSegmentedControl<ThemePreference>(
                      groupValue: state.themePreference,
                      backgroundColor: DisciplineColors.surface2,
                      thumbColor: DisciplineColors.accent.withValues(
                        alpha: 0.2,
                      ),
                      children: <ThemePreference, Widget>{
                        ThemePreference.system: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            'System',
                            style: DisciplineTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ThemePreference.light: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            'Light',
                            style: DisciplineTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ThemePreference.dark: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            'Dark',
                            style: DisciplineTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (selection) {
                        if (selection == null) return;
                        app.setThemePreference(selection);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DisciplineCard(
                child: Row(
                  children: <Widget>[
                    ProgressRing(
                      progress: state.streakProgress,
                      size: 92,
                      strokeWidth: 8,
                      animate: false,
                      child: Text(
                        '${state.streakDays}',
                        style: DisciplineTextStyles.section.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            state.onboardingProfile.addictionLabel,
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${state.streakDays} day streak',
                            style: DisciplineTextStyles.section.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Days active: ${(state.streakDays * 3).clamp(7, 180)}',
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DisciplineCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Achievements',
                        style: DisciplineTextStyles.caption),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <String>[
                        'Consistency',
                        'Late-night control',
                        'Emergency mastery',
                      ].map((label) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: DisciplineColors.surface2,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: DisciplineColors.border
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                          child: Text(
                            label,
                            style: DisciplineTextStyles.caption.copyWith(
                              color: DisciplineColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              row(
                title: 'Lock Mode',
                subtitle: state.onboardingProfile.lockMode ? 'Enabled' : 'Off',
                icon: CupertinoIcons.lock,
                onTap: () => Navigator.of(context).push(
                  DisciplinePageRoute<void>(
                    builder: (_) => const LockModeScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              row(
                title: 'Notifications',
                subtitle: state.onboardingProfile.riskAlertsEnabled
                    ? 'Risk alerts on'
                    : 'Muted',
                icon: CupertinoIcons.bell,
                onTap: () => Navigator.of(context).push(
                  DisciplinePageRoute<void>(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              row(
                title: 'Subscription',
                subtitle: state.isPremium ? 'Premium active' : 'Standard plan',
                icon: CupertinoIcons.creditcard,
                onTap: () => Navigator.of(context).push(
                  DisciplinePageRoute<void>(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DisciplineButton(
                label: 'Sign Out',
                variant: DisciplineButtonVariant.secondary,
                onPressed: app.signOut,
              ),
            ],
          ),
        );
      },
    );
  }
}
