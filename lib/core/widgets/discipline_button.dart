import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';
import '../theme/discipline_text_styles.dart';
import '../theme/discipline_tokens.dart';
import '../utils/haptics.dart';

enum DisciplineButtonVariant { primary, secondary, danger }

class DisciplineButton extends StatefulWidget {
  const DisciplineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DisciplineButtonVariant.primary,
    this.expand = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final DisciplineButtonVariant variant;
  final bool expand;
  final IconData? icon;

  @override
  State<DisciplineButton> createState() => _DisciplineButtonState();
}

class _DisciplineButtonState extends State<DisciplineButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final reduceMotion = DisciplineMotion.reduceMotion(context);

    final backgroundColor = switch (widget.variant) {
      DisciplineButtonVariant.primary => DisciplineColors.accent,
      DisciplineButtonVariant.secondary => DisciplineColors.surface2,
      DisciplineButtonVariant.danger => DisciplineColors.danger,
    };

    final borderColor = switch (widget.variant) {
      DisciplineButtonVariant.primary => DisciplineColors.accent,
      DisciplineButtonVariant.secondary => DisciplineColors.border,
      DisciplineButtonVariant.danger => DisciplineColors.danger,
    };

    final labelColor = switch (widget.variant) {
      DisciplineButtonVariant.primary => DisciplineColors.background,
      DisciplineButtonVariant.secondary => DisciplineColors.textPrimary,
      DisciplineButtonVariant.danger => DisciplineColors.background,
    };

    final child = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: isEnabled ? 1 : 0.45),
        borderRadius: BorderRadius.circular(DisciplineRadii.button),
        border: Border.all(color: borderColor.withValues(alpha: 0.7)),
        boxShadow: widget.variant == DisciplineButtonVariant.primary &&
                isEnabled
            ? <BoxShadow>[
                BoxShadow(
                  color: DisciplineColors.accentGlow.withValues(alpha: 0.65),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 18, color: labelColor),
            const SizedBox(width: 10),
          ],
          Text(widget.label,
              style: DisciplineTextStyles.button.copyWith(color: labelColor)),
        ],
      ),
    );

    return SizedBox(
      width: widget.expand ? double.infinity : null,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: isEnabled ? (_) => _setPressed(true) : null,
          onTapUp: isEnabled ? (_) => _setPressed(false) : null,
          onTapCancel: isEnabled ? () => _setPressed(false) : null,
          onTap: isEnabled
              ? () {
                  Haptics.light();
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
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class DisciplineTextButton extends StatelessWidget {
  const DisciplineTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = DisciplineColors.textSecondary,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      onPressed: onPressed,
      child: Text(
        label,
        style: DisciplineTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}
