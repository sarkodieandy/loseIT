import 'dart:ui' show ColorSpace, PlatformDispatcher;

import 'package:flutter/cupertino.dart';

class DisciplineColors {
  static Brightness? _brightnessOverride;
  static Brightness? _transitionFrom;
  static Brightness? _transitionTo;
  static double _transitionProgress = 1;

  static void setBrightnessOverride(Brightness? brightness) {
    _brightnessOverride = brightness;
    _transitionFrom = null;
    _transitionTo = null;
    _transitionProgress = 1;
  }

  static void setBrightnessTransition({
    required Brightness from,
    required Brightness to,
    required double progress,
  }) {
    _brightnessOverride = to;
    _transitionFrom = from;
    _transitionTo = to;
    _transitionProgress = progress.clamp(0.0, 1.0).toDouble();
  }

  static const background = _AdaptiveColor(
    light: Color(0xFFF5F7FB),
    dark: Color(0xFF0E0F12),
  );
  static const backgroundTop = _AdaptiveColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF11141A),
  );
  static const surface = _AdaptiveColor(
    light: Color(0xFFFFFFFF),
    dark: Color(0xFF14161B),
  );
  static const surface2 = _AdaptiveColor(
    light: Color(0xFFEFF3FA),
    dark: Color(0xFF1A1D24),
  );
  static const border = _AdaptiveColor(
    light: Color(0xFFD7DFEB),
    dark: Color(0xFF262A33),
  );

  static const textPrimary = _AdaptiveColor(
    light: Color(0xFF0F172A),
    dark: Color(0xFFECEFF4),
  );
  static const textSecondary = _AdaptiveColor(
    light: Color(0xFF475569),
    dark: Color(0xFF9AA4B2),
  );
  static const textTertiary = _AdaptiveColor(
    light: Color(0xFF64748B),
    dark: Color(0xFF6B7280),
  );

  // Accent: Deep Teal (refined, calm).
  static const accent = _AdaptiveColor(
    light: Color(0xFF129A8E),
    dark: Color(0xFF1CC7B6),
  );
  static const accentGlow = _AdaptiveColor(
    light: Color(0x1F129A8E),
    dark: Color(0x331CC7B6),
  );

  static const danger = _AdaptiveColor(
    light: Color(0xFFB85A5A),
    dark: Color(0xFFB25A5A),
  );
  static const dangerGlow = _AdaptiveColor(
    light: Color(0x1FB85A5A),
    dark: Color(0x33B25A5A),
  );

  static const warning = _AdaptiveColor(
    light: Color(0xFFB58715),
    dark: Color(0xFFE0B84D),
  );
  static const success = _AdaptiveColor(
    light: Color(0xFF1F9A5C),
    dark: Color(0xFF2FBF71),
  );

  static const navBarScrim = _AdaptiveColor(
    light: Color(0xE6FFFFFF),
    dark: Color(0xE60E0F12),
  );
}

class _AdaptiveColor extends Color {
  const _AdaptiveColor({required this.light, required this.dark})
      : super(0x00000000);

  final Color light;
  final Color dark;

  Color _colorFor(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  Color get _effectiveColor {
    final from = DisciplineColors._transitionFrom;
    final to = DisciplineColors._transitionTo;
    if (from != null && to != null && from != to) {
      final progress = DisciplineColors._transitionProgress;
      if (progress <= 0) return _colorFor(from);
      if (progress >= 1) return _colorFor(to);
      return Color.lerp(_colorFor(from), _colorFor(to), progress) ??
          _colorFor(to);
    }

    final brightness = DisciplineColors._brightnessOverride ??
        PlatformDispatcher.instance.platformBrightness;
    return _colorFor(brightness);
  }

  @override
  int get value => _effectiveColor.toARGB32();

  @override
  int toARGB32() => _effectiveColor.toARGB32();

  @override
  int get alpha => (a * 255.0).round().clamp(0, 255);

  @override
  int get blue => (b * 255.0).round().clamp(0, 255);

  @override
  double computeLuminance() => _effectiveColor.computeLuminance();

  @override
  int get green => (g * 255.0).round().clamp(0, 255);

  @override
  double get opacity => a;

  @override
  int get red => (r * 255.0).round().clamp(0, 255);

  @override
  Color withAlpha(int a) => _effectiveColor.withAlpha(a);

  @override
  Color withBlue(int b) => _effectiveColor.withBlue(b);

  @override
  Color withGreen(int g) => _effectiveColor.withGreen(g);

  @override
  Color withOpacity(double opacity) => _effectiveColor.withValues(
        alpha: opacity,
      );

  @override
  Color withRed(int r) => _effectiveColor.withRed(r);

  @override
  double get a => _effectiveColor.a;

  @override
  double get r => _effectiveColor.r;

  @override
  double get g => _effectiveColor.g;

  @override
  double get b => _effectiveColor.b;

  @override
  ColorSpace get colorSpace => _effectiveColor.colorSpace;

  @override
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
    ColorSpace? colorSpace,
  }) => _effectiveColor.withValues(
        alpha: alpha,
        red: red,
        green: green,
        blue: blue,
        colorSpace: colorSpace,
      );
}
