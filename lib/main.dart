import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/app_provider_observer.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    AppLogger.info('App starting');
    await AppBootstrap.initialize();
    AppLogger.info('App bootstrap complete');

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'FlutterError.onError',
        details.exception,
        details.stack,
      );
    };

    ErrorWidget.builder = (details) {
      // always log the underlying issue
      AppLogger.error(
        'ErrorWidget.builder',
        details.exception,
        details.stack,
      );
      // show a visible error message even in release builds. Wrap the
      // content in its own Directionality/Material so it can render anywhere
      // in the tree (e.g. before the app's normal widgets are available).
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              color: Colors.red.shade700.withValues(alpha: 0.8),
              padding: const EdgeInsets.all(16),
              child: Text(
                details.exception.toString(),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    };

    runApp(
      ProviderScope(
        observers: <ProviderObserver>[AppProviderObserver()],
        child: const BeSoberApp(),
      ),
    );
  }, (error, stackTrace) {
    AppLogger.error('zone', error, stackTrace);
  });
}
