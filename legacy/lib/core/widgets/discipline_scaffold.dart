import 'package:flutter/cupertino.dart';

import '../theme/discipline_colors.dart';
import 'app_background.dart';

class DisciplineScaffold extends StatelessWidget {
  const DisciplineScaffold({
    super.key,
    required this.child,
    this.title,
    this.leading,
    this.trailing,
    this.safeAreaTop,
    this.safeAreaBottom = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final bool? safeAreaTop;
  final bool safeAreaBottom;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final navBar = title == null
        ? null
        : CupertinoNavigationBar(
            backgroundColor: DisciplineColors.navBarScrim,
            border: null,
            leading: leading,
            trailing: trailing,
            middle: Text(title!),
          );

    return CupertinoPageScaffold(
      backgroundColor: DisciplineColors.background,
      navigationBar: navBar,
      child: AppBackground(
        child: SafeArea(
          top: safeAreaTop ?? navBar == null,
          bottom: safeAreaBottom,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
