import 'package:flutter/cupertino.dart';

import '../core/theme/discipline_theme.dart';
import 'app_controller.dart';
import 'app_entry.dart';

class DisciplineApp extends StatefulWidget {
  const DisciplineApp({super.key});

  @override
  State<DisciplineApp> createState() => _DisciplineAppState();
}

class _DisciplineAppState extends State<DisciplineApp> {
  late final AppController _controller;

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
    return AppScope(
      controller: _controller,
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        theme: DisciplineTheme.cupertinoDark,
        home: const AppEntry(),
      ),
    );
  }
}
