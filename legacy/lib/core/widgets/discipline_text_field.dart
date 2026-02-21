import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';
import '../theme/discipline_text_styles.dart';
import '../theme/discipline_tokens.dart';
import 'discipline_card.dart';

class DisciplineTextField extends StatelessWidget {
  const DisciplineTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffix,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
  });

  final String label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffix;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final error = (errorText ?? '').trim().isNotEmpty;

        final activeColor = error
            ? DisciplineColors.danger
            : focused
                ? DisciplineColors.accent
                : DisciplineColors.border;

        return DisciplineCard(
          padding: const EdgeInsets.all(14),
          borderColor: (focused || error) ? activeColor : null,
          shadow: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: DisciplineTextStyles.caption),
              const SizedBox(height: 10),
              CupertinoTextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                autofillHints: autofillHints,
                obscureText: obscureText,
                style: DisciplineTextStyles.body,
                placeholder: placeholder,
                placeholderStyle: DisciplineTextStyles.secondary,
                cursorColor: DisciplineColors.accent,
                onSubmitted: onSubmitted,
                onChanged: onChanged,
                suffix: suffix,
                maxLines: maxLines,
                decoration: BoxDecoration(
                  color: DisciplineColors.surface2,
                  borderRadius: BorderRadius.circular(DisciplineRadii.field),
                  border: Border.all(
                    color: activeColor.withValues(
                      alpha: focused || error ? 0.85 : 0.65,
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: DisciplineMotion.fast,
                  switchInCurve: DisciplineMotion.standard,
                  switchOutCurve: DisciplineMotion.standard,
                  child: error
                      ? Row(
                          key: const ValueKey<String>('error'),
                          children: <Widget>[
                            const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              size: 14,
                              color: DisciplineColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorText!,
                                style: DisciplineTextStyles.caption.copyWith(
                                  color: DisciplineColors.danger,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(
                          key: ValueKey<String>('no-error'),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
