import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../model/addiction_type.dart';
import '../onboarding_flow.dart';
import '../widgets/addiction_card.dart';

class AddictionSelectionScreen extends StatefulWidget {
  const AddictionSelectionScreen({super.key});

  @override
  State<AddictionSelectionScreen> createState() =>
      _AddictionSelectionScreenState();
}

class _AddictionSelectionScreenState extends State<AddictionSelectionScreen> {
  AddictionType? _selected;
  late final TextEditingController _customController;
  bool _didInitFromState = false;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromState) return;
    final profile = AppScope.of(context).state.onboardingProfile;
    _selected = profile.addictionType;
    _customController.text = profile.customAddictionLabel;
    _didInitFromState = true;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  IconData _iconFor(AddictionType type) {
    return switch (type) {
      AddictionType.smoking => CupertinoIcons.flame,
      AddictionType.gambling => CupertinoIcons.money_dollar_circle,
      AddictionType.porn => CupertinoIcons.eye,
      AddictionType.alcohol => CupertinoIcons.drop,
      AddictionType.socialMedia => CupertinoIcons.chat_bubble_text,
      AddictionType.custom => CupertinoIcons.slider_horizontal_3,
    };
  }

  void _commitSelection(AppController controller) {
    final selected = _selected;
    final current = controller.state.onboardingProfile;
    controller.updateOnboardingProfile(
      current.copyWith(
        addictionType: selected,
        customAddictionLabel: _customController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return DisciplineScaffold(
      title: 'Select Focus',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 10),
          const Text(
            'What are you controlling?',
            style: DisciplineTextStyles.title,
          ),
          const SizedBox(height: 10),
          Text(
            'Choose one primary target. You can adjust later.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.85,
              children: AddictionType.values.map((type) {
                final selected = _selected == type;
                return AddictionCard(
                  label: type.label,
                  icon: _iconFor(type),
                  selected: selected,
                  onTap: () {
                    Haptics.selection();
                    setState(() {
                      _selected = type;
                    });
                    _commitSelection(controller);
                  },
                );
              }).toList(),
            ),
          ),
          if (_selected == AddictionType.custom) ...[
            DisciplineCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('Custom label',
                      style: DisciplineTextStyles.caption),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _customController,
                    placeholder: 'e.g., Nicotine, Gaming, Shopping',
                    onChanged: (_) => _commitSelection(controller),
                    style: DisciplineTextStyles.body,
                    placeholderStyle: DisciplineTextStyles.secondary,
                    cursorColor: DisciplineColors.accent,
                    decoration: BoxDecoration(
                      color: DisciplineColors.surface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: DisciplineColors.border.withValues(alpha: 0.7),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          DisciplineButton(
            label: 'Continue',
            onPressed: _selected == null
                ? null
                : () {
                    _commitSelection(controller);
                    Navigator.of(context).pushNamed(OnboardingFlow.severity);
                  },
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
