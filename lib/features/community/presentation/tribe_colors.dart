import 'package:flutter/material.dart';

/// Shared color palette for tribe/community screens which adapts to the
/// current [Theme] brightness.  Made public (no leading underscore) so it can
/// be referenced from multiple files.
class TribeColors {
  static Color bgTop(BuildContext context) => Theme.of(context).colorScheme.surface;

  static Color bgBottom(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color card(BuildContext context) =>
      Theme.of(context).cardTheme.color ??
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color cardBorder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return scheme.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.55);
  }

  static Color muted(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  // Primary accent should match the app's primary color.
  static Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color green(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color red(BuildContext context) => Theme.of(context).colorScheme.error;

  static Color chip(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color textPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  static Color field(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
}
