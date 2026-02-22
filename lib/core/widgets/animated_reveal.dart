import 'package:flutter/material.dart';

import '../utils/app_motion.dart';

/// A small, production-friendly entrance animation for cards/sections.
///
/// - Fades in
/// - Slides up slightly
/// - Scales in subtly
///
/// It runs once when the widget is first inserted into the tree. Give it a
/// stable [Key] (e.g. `ValueKey(id)`) for list items so it doesn't restart on
/// rebuilds.
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.curve = AppMotion.emphasized,
    this.beginOffset = const Offset(0, 0.06),
    this.beginScale = 0.985,
    this.enabled = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final double beginScale;
  final bool enabled;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _shown = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(widget.delay, () {
        if (!mounted) return;
        setState(() => _shown = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Respect iOS accessibility settings (Reduce Motion / Accessible Navigation).
    final reduceMotion = MediaQuery.of(context).accessibleNavigation;
    if (reduceMotion || !widget.enabled) {
      return widget.child;
    }

    final duration = widget.duration;
    final curve = widget.curve;
    final shown = _shown;

    return AnimatedOpacity(
      opacity: shown ? 1 : 0,
      duration: duration,
      curve: curve,
      child: AnimatedSlide(
        offset: shown ? Offset.zero : widget.beginOffset,
        duration: duration,
        curve: curve,
        child: AnimatedScale(
          scale: shown ? 1 : widget.beginScale,
          duration: duration,
          curve: curve,
          child: widget.child,
        ),
      ),
    );
  }
}

