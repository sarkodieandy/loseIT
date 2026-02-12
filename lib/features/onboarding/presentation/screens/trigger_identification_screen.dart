import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../model/trigger_type.dart';
import '../onboarding_flow.dart';
import '../widgets/trigger_tile.dart';

class TriggerIdentificationScreen extends StatefulWidget {
  const TriggerIdentificationScreen({super.key});

  @override
  State<TriggerIdentificationScreen> createState() =>
      _TriggerIdentificationScreenState();
}

class _TriggerIdentificationScreenState
    extends State<TriggerIdentificationScreen> {
  late Set<TriggerType> _selected;
  bool _didInitFromState = false;

  @override
  void initState() {
    super.initState();
    _selected = <TriggerType>{};
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromState) return;
    _selected = {...AppScope.of(context).state.onboardingProfile.triggers};
    _didInitFromState = true;
  }

  IconData _iconFor(TriggerType trigger) {
    return switch (trigger) {
      TriggerType.stress => CupertinoIcons.bolt,
      TriggerType.boredom => CupertinoIcons.hourglass,
      TriggerType.loneliness => CupertinoIcons.person_2,
      TriggerType.anxiety => CupertinoIcons.heart,
      TriggerType.fatigue => CupertinoIcons.moon,
      TriggerType.conflict => CupertinoIcons.exclamationmark_triangle,
      TriggerType.socialPressure => CupertinoIcons.group,
      TriggerType.lateNight => CupertinoIcons.time,
      TriggerType.alcohol => CupertinoIcons.drop,
      TriggerType.celebration => CupertinoIcons.sparkles,
    };
  }

  void _commit(AppController controller) {
    controller.updateOnboardingProfile(
      controller.state.onboardingProfile.copyWith(triggers: _selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return DisciplineScaffold(
      title: 'Triggers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),
          const Text('Identify triggers.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Select what typically precedes an urge. The AI uses this to predict risk windows.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.builder(
              itemCount: TriggerType.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.25,
              ),
              itemBuilder: (context, index) {
                final trigger = TriggerType.values[index];
                final selected = _selected.contains(trigger);
                return TriggerTile(
                  label: trigger.label,
                  icon: _iconFor(trigger),
                  selected: selected,
                  onTap: () {
                    Haptics.selection();
                    setState(() {
                      if (selected) {
                        _selected.remove(trigger);
                      } else {
                        _selected.add(trigger);
                      }
                    });
                    _commit(controller);
                  },
                );
              },
            ),
          ),
          DisciplineButton(
            label: 'Continue',
            onPressed: () {
              _commit(controller);
              Navigator.of(context).pushNamed(OnboardingFlow.riskTime);
            },
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
