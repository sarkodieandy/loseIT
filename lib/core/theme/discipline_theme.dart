import 'package:flutter/cupertino.dart';

import 'discipline_colors.dart';

class DisciplineTheme {
  static const CupertinoThemeData _baseCupertino = CupertinoThemeData(
    primaryColor: DisciplineColors.accent,
    primaryContrastingColor: DisciplineColors.background,
    scaffoldBackgroundColor: DisciplineColors.background,
    barBackgroundColor: DisciplineColors.navBarScrim,
  );

  static CupertinoThemeData cupertino({Brightness? brightness}) {
    return _baseCupertino.copyWith(brightness: brightness);
  }
}
