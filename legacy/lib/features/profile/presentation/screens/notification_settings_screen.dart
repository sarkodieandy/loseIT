import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/time_slots.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _pickReminderTime(
      BuildContext context, AppController app) async {
    final initial = app.state.onboardingProfile.dailyReminderMinutes;
    final initialDate = DateTime(2020, 1, 1, initial ~/ 60, initial % 60);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        var minutes = initial;
        return SafeArea(
          top: false,
          child: Container(
            height: 310,
            decoration: BoxDecoration(
              color: DisciplineColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(
                  color: DisciplineColors.border.withValues(alpha: 0.75)),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: DisciplineColors.border.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    CupertinoButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    CupertinoButton(
                      onPressed: () {
                        app.updateOnboardingProfile(
                          app.state.onboardingProfile.copyWith(
                            dailyReminderMinutes: minutes,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDate,
                    use24hFormat: false,
                    onDateTimeChanged: (dt) {
                      minutes = dt.hour * 60 + dt.minute;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final profile = app.state.onboardingProfile;

        Widget toggleRow({
          required String title,
          required String subtitle,
          required bool value,
          required ValueChanged<bool> onChanged,
        }) {
          return DisciplineCard(
            shadow: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
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
                CupertinoSwitch(
                  value: value,
                  activeTrackColor: DisciplineColors.accent,
                  onChanged: onChanged,
                ),
              ],
            ),
          );
        }

        return DisciplineScaffold(
          title: 'Notifications',
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            children: <Widget>[
              const Text('Risk alerts.', style: DisciplineTextStyles.title),
              const SizedBox(height: 10),
              Text(
                'Control what the system surfaces and when.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 18),
              toggleRow(
                title: 'Risk alerts',
                subtitle: 'Notifications during vulnerable windows.',
                value: profile.riskAlertsEnabled,
                onChanged: (v) => app.setRiskAlerts(v),
              ),
              const SizedBox(height: 12),
              toggleRow(
                title: 'Daily reminder',
                subtitle: 'A single subtle check-in prompt.',
                value: profile.dailyReminderEnabled,
                onChanged: (v) {
                  app.updateOnboardingProfile(
                    profile.copyWith(dailyReminderEnabled: v),
                  );
                },
              ),
              const SizedBox(height: 12),
              DisciplineCard(
                shadow: false,
                onTap: profile.dailyReminderEnabled
                    ? () => _pickReminderTime(context, app)
                    : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Reminder time',
                        style: DisciplineTextStyles.section),
                    Text(
                      formatMinutesTime(profile.dailyReminderMinutes),
                      style: DisciplineTextStyles.caption.copyWith(
                        color: profile.dailyReminderEnabled
                            ? DisciplineColors.textSecondary
                            : DisciplineColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
