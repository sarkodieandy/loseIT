import 'package:flutter/cupertino.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../services/supabase/supabase_error_text.dart';

enum _Mode { join, create }

class JoinCreateGroupSheet extends StatefulWidget {
  const JoinCreateGroupSheet({super.key});

  @override
  State<JoinCreateGroupSheet> createState() => _JoinCreateGroupSheetState();
}

class _JoinCreateGroupSheetState extends State<JoinCreateGroupSheet> {
  _Mode _mode = _Mode.join;
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final title = _mode == _Mode.join ? 'Join Group' : 'Create Group';
    final placeholder =
        _mode == _Mode.join ? 'Enter group code' : 'Enter group name';

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: DisciplineColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(
              color: DisciplineColors.border.withValues(alpha: 0.75),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: DisciplineColors.border.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(title, style: DisciplineTextStyles.section),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 18,
                      color: DisciplineColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CupertinoSegmentedControl<_Mode>(
                groupValue: _mode,
                selectedColor: DisciplineColors.accent.withValues(alpha: 0.16),
                unselectedColor: DisciplineColors.surface2,
                borderColor: DisciplineColors.border.withValues(alpha: 0.7),
                pressedColor: DisciplineColors.accent.withValues(alpha: 0.10),
                children: const <_Mode, Widget>{
                  _Mode.join: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('Join'),
                  ),
                  _Mode.create: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('Create'),
                  ),
                },
                onValueChanged: (value) => setState(() => _mode = value),
              ),
              const SizedBox(height: 14),
              CupertinoTextField(
                controller: _controller,
                placeholder: placeholder,
                style: DisciplineTextStyles.body,
                placeholderStyle: DisciplineTextStyles.secondary,
                cursorColor: DisciplineColors.accent,
                decoration: BoxDecoration(
                  color: DisciplineColors.surface2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: DisciplineColors.border.withValues(alpha: 0.7),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: DisciplineTextStyles.caption.copyWith(
                      color: DisciplineColors.danger,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              DisciplineButton(
                label: _busy ? 'Working…' : 'Continue',
                onPressed: _busy
                    ? null
                    : () async {
                  final text = _controller.text.trim();
                  if (text.isEmpty) return;
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  try {
                    final group = switch (_mode) {
                      _Mode.join =>
                        await app.services.community.joinGroup(code: text),
                      _Mode.create =>
                        await app.services.community.createGroup(name: text),
                    };
                    if (!mounted) return;
                    Navigator.of(context).pop(group);
                  } catch (error, stackTrace) {
                    AppLogger.error(
                      'JoinCreateGroupSheet.continue',
                      error,
                      stackTrace,
                    );
                    if (!mounted) return;
                    setState(() {
                      _error = supabaseErrorText(error);
                    });
                  } finally {
                    if (mounted) {
                      setState(() => _busy = false);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
