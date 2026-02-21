import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';
import '../theme/discipline_tokens.dart';
import '../utils/haptics.dart';

class DisciplineCard extends StatefulWidget {
  const DisciplineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final bool shadow;

  @override
  State<DisciplineCard> createState() => _DisciplineCardState();
}

class _DisciplineCardState extends State<DisciplineCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = DisciplineMotion.reduceMotion(context);
    final content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? DisciplineColors.surface,
        borderRadius: BorderRadius.circular(DisciplineRadii.card),
        border: Border.all(
          color: (widget.borderColor ?? DisciplineColors.border)
              .withValues(alpha: 0.75),
        ),
        boxShadow: widget.shadow
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return content;

    return Semantics(
      button: true,
      enabled: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () {
          Haptics.selection();
          widget.onTap?.call();
        },
        child: AnimatedScale(
          scale: (!reduceMotion && _pressed) ? 0.992 : 1,
          duration: DisciplineMotion.fast,
          curve: DisciplineMotion.standard,
          child: AnimatedOpacity(
            opacity: (!reduceMotion && _pressed) ? 0.98 : 1,
            duration: DisciplineMotion.fast,
            curve: DisciplineMotion.standard,
            child: content,
          ),
        ),
      ),
    );
  }
}
