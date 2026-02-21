import 'package:health/health.dart';

import '../../core/utils/app_logger.dart';

class HealthService {
  HealthService._();

  static final HealthService instance = HealthService._();

  final Health _health = Health();

  Future<bool> requestAuthorization() async {
    final types = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.HEART_RATE,
    ];
    final permissions = types.map((_) => HealthDataAccess.READ).toList();
    try {
      return await _health.requestAuthorization(types, permissions: permissions);
    } catch (error, stackTrace) {
      AppLogger.error('health.auth', error, stackTrace);
      return false;
    }
  }

  Future<int> fetchSteps(DateTime from, DateTime to) async {
    try {
      final steps = await _health.getTotalStepsInInterval(from, to);
      return steps ?? 0;
    } catch (error, stackTrace) {
      AppLogger.error('health.steps', error, stackTrace);
      return 0;
    }
  }
}
