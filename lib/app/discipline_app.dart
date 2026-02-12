import 'package:flutter/cupertino.dart';

import '../core/theme/discipline_colors.dart';
import '../core/theme/discipline_theme.dart';
import '../core/theme/theme_preference.dart';
import 'app_controller.dart';
import 'app_entry.dart';

class DisciplineApp extends StatefulWidget {
  const DisciplineApp({super.key});

  @override
  State<DisciplineApp> createState() => _DisciplineAppState();
}

class _DisciplineAppState extends State<DisciplineApp> {
  late final AppController _controller;

  Brightness? _brightnessFor(ThemePreference preference) {
    return switch (preference) {
      ThemePreference.system => null,
      ThemePreference.light => Brightness.light,
      ThemePreference.dark => Brightness.dark,
    };
  }

  @override
  void initState() {
    super.initState();
    _controller = AppController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final brightness = _brightnessFor(_controller.state.themePreference);
        DisciplineColors.setBrightnessOverride(brightness);

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
