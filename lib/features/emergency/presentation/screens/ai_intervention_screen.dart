import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../emergency_flow.dart';

class AiInterventionScreen extends StatelessWidget {
  const AiInterventionScreen({super.key, this.onExit, required this.showClose});

  final VoidCallback? onExit;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    return DisciplineScaffold(
      title: 'Intervention',
      trailing: showClose
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onExit,
              child: const Icon(CupertinoIcons.xmark),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 14),
          const Text('Pause.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Urges peak quickly. You just created a gap — now choose the next action deliberately.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          const DisciplineCard(
            child: Text(
              'Name the feeling. Locate it in the body. Reduce the decision to the next 60 seconds.',
              style: DisciplineTextStyles.section,
            ),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Continue',
            onPressed: () =>
                Navigator.of(context).pushNamed(EmergencyFlow.challenge),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
