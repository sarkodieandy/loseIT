import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/cupertino.dart';

import '../core/theme/discipline_colors.dart';
import '../core/theme/discipline_theme.dart';
import '../core/theme/discipline_tokens.dart';
import '../core/theme/theme_preference.dart';
import '../services/discipline_services.dart';
import 'app_controller.dart';
import 'app_entry.dart';

class DisciplineApp extends StatefulWidget {
  const DisciplineApp({
    super.key,
    required this.services,
  });

  final DisciplineServices services;

  @override
  State<DisciplineApp> createState() => _DisciplineAppState();
}

class _DisciplineAppState extends State<DisciplineApp>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AppController _controller;
  late final AnimationController _themeTransitionController;
  late Brightness _transitionFromBrightness;
  late Brightness _transitionToBrightness;
  late ThemePreference _lastThemePreference;
  late Brightness _lastPlatformBrightness;

  Brightness get _platformBrightness => PlatformDispatcher.instance.platformBrightness;

  Brightness _resolvedBrightnessFor(
    ThemePreference preference, {
    Brightness? platformBrightness,
  }) {
    final effectivePlatformBrightness = platformBrightness ?? _platformBrightness;
    return switch (preference) {
      ThemePreference.system => effectivePlatformBrightness,
      ThemePreference.light => Brightness.light,
      ThemePreference.dark => Brightness.dark,
    };
  }

  Brightness _currentVisualBrightness() {
    final progress = _themeTransitionController.value;
    if (_transitionFromBrightness == _transitionToBrightness) {
      return _transitionToBrightness;
    }
    return progress < 0.5 ? _transitionFromBrightness : _transitionToBrightness;
  }

  void _syncThemeTransition({bool force = false}) {
    final preference = _controller.state.themePreference;
    final platformBrightness = _platformBrightness;
    final targetBrightness = _resolvedBrightnessFor(
      preference,
      platformBrightness: platformBrightness,
    );

    final preferenceChanged = _lastThemePreference != preference;
    final platformChanged = preference == ThemePreference.system &&
        _lastPlatformBrightness != platformBrightness;

    if (!force &&
        !preferenceChanged &&
        !platformChanged &&
        targetBrightness == _transitionToBrightness) {
      return;
    }

    _lastThemePreference = preference;
    _lastPlatformBrightness = platformBrightness;

    _transitionFromBrightness = _currentVisualBrightness();
    _transitionToBrightness = targetBrightness;

    if (_transitionFromBrightness == _transitionToBrightness) {
      _themeTransitionController.value = 1;
      return;
    }

    _themeTransitionController.forward(from: 0);
  }

  void _handleControllerChanged() {
    _syncThemeTransition();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = AppController(services: widget.services);

    _lastThemePreference = _controller.state.themePreference;
    _lastPlatformBrightness = _platformBrightness;
    _transitionToBrightness = _resolvedBrightnessFor(
      _lastThemePreference,
      platformBrightness: _lastPlatformBrightness,
    );
    _transitionFromBrightness = _transitionToBrightness;

    _themeTransitionController = AnimationController(
      vsync: this,
      duration: DisciplineMotion.medium,
      reverseDuration: DisciplineMotion.medium,
      value: 1,
    );

    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didChangePlatformBrightness() {
    if (_controller.state.themePreference != ThemePreference.system) {
      return;
    }
    _syncThemeTransition(force: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_handleControllerChanged);
    _themeTransitionController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        <Listenable>[_controller, _themeTransitionController],
      ),
      builder: (context, _) {
        final progress = DisciplineMotion.reduceMotion(context)
            ? 1.0
            : Curves.easeInOutCubic.transform(_themeTransitionController.value);
        final brightness = progress < 0.5
            ? _transitionFromBrightness
            : _transitionToBrightness;

        DisciplineColors.setBrightnessTransition(
          from: _transitionFromBrightness,
          to: _transitionToBrightness,
          progress: progress,
        );

        return AppScope(
          controller: _controller,
          child: CupertinoApp(
            debugShowCheckedModeBanner: false,
            theme: DisciplineTheme.cupertino(brightness: brightness),
            home: const AppEntry(),
          ),
        );
      },
    );
  }
}
