import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../onboarding_flow.dart';

class FrequencySeverityScreen extends StatefulWidget {
  const FrequencySeverityScreen({super.key});

  @override
  State<FrequencySeverityScreen> createState() =>
      _FrequencySeverityScreenState();
}

class _FrequencySeverityScreenState extends State<FrequencySeverityScreen> {
  late double _frequency;
  late double _severity;
  bool _didInitFromState = false;

  @override
  void initState() {
    super.initState();
    _frequency = 4;
    _severity = 5;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromState) return;
    final profile = AppScope.of(context).state.onboardingProfile;
    _frequency = profile.frequency;
    _severity = profile.severity;
    _didInitFromState = true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    void commit() {
      controller.updateOnboardingProfile(
        controller.state.onboardingProfile.copyWith(
          frequency: _frequency,
          severity: _severity,
        ),
      );
    }

    Widget sliderCard({
      required String title,
      required String subtitle,
      required double value,
      required ValueChanged<double> onChanged,
    }) {
      return DisciplineCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: DisciplineTextStyles.section),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Text(
                  value.toStringAsFixed(0),
                  style: DisciplineTextStyles.section.copyWith(
                    color: DisciplineColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoSlider(
                    value: value,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: DisciplineColors.accent,
                    onChanged: (v) {
                      onChanged(v);
                      commit();
                    },
                    onChangeEnd: (_) => Haptics.selection(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return DisciplineScaffold(
      title: 'Frequency & Severity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          const Text(
            'Calibrate the system.',
            style: DisciplineTextStyles.title,
          ),
          const SizedBox(height: 10),
          Text(
            'Your inputs stay private — used only to personalize risk prediction.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          sliderCard(
            title: 'Frequency',
            subtitle: 'How often do urges typically appear?',
            value: _frequency,
            onChanged: (v) => setState(() => _frequency = v),
          ),
          const SizedBox(height: 14),
          sliderCard(
            title: 'Severity',
            subtitle: 'How hard is it to resist when it hits?',
            value: _severity,
            onChanged: (v) => setState(() => _severity = v),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Continue',
            onPressed: () {
              commit();
              Navigator.of(context).pushNamed(OnboardingFlow.triggers);
            },
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
