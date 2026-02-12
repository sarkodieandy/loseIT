import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key, this.onExit, required this.showClose});

  final VoidCallback? onExit;
  final bool showClose;

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(AppController app) async {
    app.logReflection(_controller.text);

    await showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Saved'),
          content: const Text('Reflection logged privately.'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (widget.onExit != null) {
      widget.onExit!.call();
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return DisciplineScaffold(
      title: 'Reflection',
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
          const Text('Capture the trigger.', style: DisciplineTextStyles.title),
          const SizedBox(height: 10),
          Text(
            'Short answer. One sentence. This improves pattern prediction over time.',
            style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 18),
          DisciplineCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'What triggered this urge?',
                  style: DisciplineTextStyles.caption,
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _controller,
                  placeholder: 'e.g., Stress after work. Late night scrolling.',
                  style: DisciplineTextStyles.body,
                  placeholderStyle: DisciplineTextStyles.secondary,
                  cursorColor: DisciplineColors.accent,
                  maxLines: 4,
                  decoration: BoxDecoration(
                    color: DisciplineColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: DisciplineColors.border.withValues(alpha: 0.7),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ],
            ),
          ),
          const Spacer(),
          DisciplineButton(
            label: 'Save & Exit',
            onPressed: () => _save(app),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
