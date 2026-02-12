import 'package:flutter/cupertino.dart';

import 'discipline_colors.dart';

class DisciplineTheme {
  static const CupertinoThemeData cupertinoDark = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: DisciplineColors.accent,
    primaryContrastingColor: DisciplineColors.background,
    scaffoldBackgroundColor: DisciplineColors.background,
    barBackgroundColor: DisciplineColors.navBarScrim,
    textTheme: CupertinoTextThemeData(
      primaryColor: DisciplineColors.textPrimary,
      textStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: DisciplineColors.textPrimary,
      ),
      navTitleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: DisciplineColors.textPrimary,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: DisciplineColors.textPrimary,
      ),
    ),
  );
}
