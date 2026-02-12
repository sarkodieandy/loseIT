import 'package:flutter/cupertino.dart';

import '../theme/discipline_tokens.dart';

class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.duration = DisciplineMotion.slow,
    this.delay = Duration.zero,
    this.dy = 10,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double dy;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _shouldAnimate = true;
  bool _didStart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: DisciplineMotion.standard,
    );
    _slide = Tween<Offset>(
      begin: Offset(0, widget.dy / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DisciplineMotion.standard,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shouldAnimate = !DisciplineMotion.reduceMotion(context);
    if (!_shouldAnimate) {
      _controller.value = 1;
      return;
    }
    if (_didStart) return;
    _didStart = true;

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
