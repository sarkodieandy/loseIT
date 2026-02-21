import 'package:flutter/cupertino.dart';

import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/theme/discipline_tokens.dart';
import '../../../../core/utils/haptics.dart';

enum SocialAuthButtonStyle { primary, secondary }

class SocialAuthButton extends StatefulWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    required this.onPressed,
    this.style = SocialAuthButtonStyle.secondary,
  })  : assert(icon != null || leading != null),
        assert(icon == null || leading == null);

  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final SocialAuthButtonStyle style;

  @override
  State<SocialAuthButton> createState() => _SocialAuthButtonState();
}

class _SocialAuthButtonState extends State<SocialAuthButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = switch (widget.style) {
      SocialAuthButtonStyle.primary => DisciplineColors.textPrimary,
      SocialAuthButtonStyle.secondary => DisciplineColors.surface2,
    };
    final fg = switch (widget.style) {
      SocialAuthButtonStyle.primary => DisciplineColors.background,
      SocialAuthButtonStyle.secondary => DisciplineColors.textPrimary,
    };
    final reduceMotion = DisciplineMotion.reduceMotion(context);

    final leadingWidget = IconTheme(
      data: IconThemeData(color: fg, size: 18),
      child: DefaultTextStyle(
        style: DisciplineTextStyles.button.copyWith(color: fg),
        child: widget.leading ?? Icon(widget.icon, size: 18),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: enabled
              ? () {
                  Haptics.selection();
                  widget.onPressed?.call();
                }
              : null,
          child: AnimatedScale(
            scale: (!reduceMotion && _pressed) ? 0.985 : 1,
            duration: DisciplineMotion.fast,
            curve: DisciplineMotion.standard,
            child: AnimatedOpacity(
              opacity: (!reduceMotion && _pressed) ? 0.96 : 1,
              duration: DisciplineMotion.fast,
              curve: DisciplineMotion.standard,
              child: AnimatedContainer(
                duration: DisciplineMotion.fast,
                curve: DisciplineMotion.standard,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg.withValues(alpha: enabled ? 1 : 0.35),
                  borderRadius: BorderRadius.circular(DisciplineRadii.button),
                  border: Border.all(
                    color: (widget.style == SocialAuthButtonStyle.primary
                            ? DisciplineColors.textPrimary
                            : DisciplineColors.border)
                        .withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    leadingWidget,
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: DisciplineTextStyles.button.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
