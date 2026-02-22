import 'package:flutter/animation.dart';

/// Central place for motion tuning (durations + curves).
///
/// Keep these values consistent across the app so animations feel cohesive.
class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);
  static const Duration slower = Duration(milliseconds: 650);

  /// Material-ish emphasized curve (snappy, not bouncy).
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve standard = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static Duration stagger(int index, {int stepMs = 45, int maxSteps = 10}) {
    final clamped = index.clamp(0, maxSteps);
    return Duration(milliseconds: stepMs * clamped);
  }
}

