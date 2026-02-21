import 'package:flutter/cupertino.dart';

class DisciplineRadii {
  static const double field = 14;
  static const double button = 18;
  static const double card = 18;
  static const double sheet = 26;
  static const double pill = 999;
}

class DisciplineMotion {
  static const Duration quick = Duration(milliseconds: 140);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration route = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;

  static bool reduceMotion(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return false;
    return mq.accessibleNavigation;
  }
}
