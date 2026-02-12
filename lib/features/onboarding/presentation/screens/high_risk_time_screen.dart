import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/time_slots.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../onboarding_flow.dart';
import '../widgets/risk_timeline_selector.dart';

class HighRiskTimeScreen extends StatefulWidget {
  const HighRiskTimeScreen({super.key});

  @override
  State<HighRiskTimeScreen> createState() => _HighRiskTimeScreenState();
}

class _HighRiskTimeScreenState extends State<HighRiskTimeScreen> {
  Set<int> _selectedSlots = <int>{};
  bool _didInitFromState = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromState) return;
    _selectedSlots = {
      ...AppScope.of(context).state.onboardingProfile.highRiskSlots
    };
    _didInitFromState = true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    final ranges = slotRangesFrom(_selectedSlots);

    return DisciplineScaffold(
      title: 'High-Risk Time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          const Text('Mark vulnerable periods.',
              style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Tap the timeline to select when urges are most likely.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('24-hour timeline',
                    style: DisciplineTextStyles.caption),
                const SizedBox(height: 12),
                RiskTimelineSelector(
                  selectedSlots: _selectedSlots,
                  onChanged: (next) => setState(() => _selectedSlots = next),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '12 AM',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textTertiary,
                      ),
                    ),
                    Text(
                      '6 AM',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textTertiary,
                      ),
                    ),
                    Text(
                      '12 PM',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textTertiary,
                      ),
                    ),
                    Text(
                      '6 PM',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textTertiary,
                      ),
                    ),
                    Text(
                      '12 AM',
                      style: DisciplineTextStyles.caption.copyWith(
                        color: DisciplineColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (ranges.isNotEmpty) ...[
            const Text('Selected windows', style: DisciplineTextStyles.caption),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ranges.map((r) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DisciplineColors.surface2,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: DisciplineColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    formatSlotRange(r),
                    style: DisciplineTextStyles.caption.copyWith(
                      color: DisciplineColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Text(
              'No windows selected. You can continue and refine later.',
              style: DisciplineTextStyles.caption.copyWith(
                color: DisciplineColors.textTertiary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          const Spacer(),
          DisciplineButton(
            label: 'Continue',
            onPressed: () {
              controller.updateOnboardingProfile(
                controller.state.onboardingProfile.copyWith(
                  highRiskSlots: _selectedSlots,
                ),
              );
              Navigator.of(context).pushNamed(OnboardingFlow.prediction);
            },
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
