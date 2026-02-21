import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../emergency_flow.dart';
import '../widgets/challenge_row.dart';

class QuickChallengeScreen extends StatefulWidget {
  const QuickChallengeScreen({super.key, this.onExit, required this.showClose});

  final VoidCallback? onExit;
  final bool showClose;

  @override
  State<QuickChallengeScreen> createState() => _QuickChallengeScreenState();
}

class _QuickChallengeScreenState extends State<QuickChallengeScreen> {
  final _selected = <int>{};

  final _items = const <String>[
    'Drink water — slow sip',
    'Stand up and move for 2 minutes',
    'Write the next action (one sentence)',
    'Switch to Lock Mode for 1 hour',
    'Message someone you trust',
  ];

  @override
  Widget build(BuildContext context) {
    return DisciplineScaffold(
      title: 'Challenge',
      trailing: widget.showClose
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: widget.onExit,
              child: const Icon(CupertinoIcons.xmark),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 14),
          const Text('Quick discipline challenge.',
              style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Complete 1–2 actions to shift state and reduce impulse strength.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final selected = _selected.contains(i);
                return ChallengeRow(
                  label: _items[i],
                  selected: selected,
                  onTap: () {
                    Haptics.selection();
                    setState(() {
                      if (selected) {
                        _selected.remove(i);
                      } else {
                        _selected.add(i);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          DisciplineButton(
            label: 'Continue',
            onPressed: () =>
                Navigator.of(context).pushNamed(EmergencyFlow.reflection),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
