import 'package:flutter/cupertino.dart';

import 'discipline_colors.dart';

class DisciplineTextStyles {
  static const headline = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: DisciplineColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: DisciplineColors.textPrimary,
  );

  static const section = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: DisciplineColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.1,
    color: DisciplineColors.textPrimary,
  );

  static const secondary = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: -0.1,
    color: DisciplineColors.textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: -0.1,
    color: DisciplineColors.textSecondary,
  );

  static const streakNumber = TextStyle(
    fontSize: 60,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
    color: DisciplineColors.textPrimary,
  );

  static const button = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: DisciplineColors.textPrimary,
  );
}
