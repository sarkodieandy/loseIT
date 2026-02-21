import 'package:flutter/cupertino.dart';

import '../theme/discipline_tokens.dart';

class DisciplinePageRoute<T> extends CupertinoPageRoute<T> {
  DisciplinePageRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    this.enableFade = true,
    this.enableScale = true,
  });

  final bool enableFade;
  final bool enableScale;

  @override
  Duration get transitionDuration => DisciplineMotion.route;

  @override
  Duration get reverseTransitionDuration => DisciplineMotion.route;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final base = super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );

    if (DisciplineMotion.reduceMotion(context)) return base;
    if (!enableFade && !enableScale) return base;

    final curved = CurvedAnimation(
      parent: animation,
      curve: DisciplineMotion.standard,
      reverseCurve: Curves.easeInCubic,
    );

    Widget result = base;
    if (enableScale) {
      result = ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
        child: result,
      );
    }
    if (enableFade) {
      result = FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(curved),
        child: result,
      );
    }
    return result;
  }
}
