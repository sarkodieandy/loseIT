import 'package:flutter/material.dart';

/// Shared color palette for tribe/community screens which adapts to the
/// current [Theme] brightness.  Made public (no leading underscore) so it can
/// be referenced from multiple files.
class TribeColors {
  static Color bgTop(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF050607)
          : Colors.white;

  static Color bgBottom(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0B0E11)
          : const Color(0xFFF5F5F5);

  static Color card(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0E1216)
          : Colors.white;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x1AFFFFFF)
          : const Color(0xFFE0E0E0);

  static Color muted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF9AA3AB)
          : const Color(0xFF6B6B6B);

  // colors unaffected by mode
  static Color accent(BuildContext context) => const Color(0xFF26B7FF);
  static Color green(BuildContext context) => const Color(0xFF19C37D);
  static Color red(BuildContext context) => const Color(0xFFE05555);

  static Color chip(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1115)
          : const Color(0xFFF0F0F0);

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;

  static Color field(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1115)
          : const Color(0xFFF0F0F0);
}
