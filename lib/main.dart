import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/utils/app_logger.dart';

Future<void> main() async {
  await AppBootstrap.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error('FlutterError.onError', details.exception, details.stack);
  };

  ErrorWidget.builder = (details) {
    AppLogger.error(
      'ErrorWidget.builder',
      details.exception,
      details.stack,
    );
    return const SizedBox.shrink();
  };

  runApp(const ProviderScope(child: BeSoberApp()));
}
