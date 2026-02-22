import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';

class AppProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final name = provider.name ?? provider.runtimeType.toString();
    AppLogger.error('riverpod.$name', error, stackTrace);
  }
}

