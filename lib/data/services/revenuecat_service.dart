import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/utils/app_logger.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  bool _initialized = false;

  Future<void> initialize(String apiKey) async {
    if (_initialized) return;
    if (apiKey.isEmpty) {
      AppLogger.warn('RevenueCat API key missing; premium disabled.');
      return;
    }
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _initialized = true;
  }

  Future<bool> isPremium() async {
    if (!_initialized) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('premium');
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.isPremium', error, stackTrace);
      return false;
    }
  }

  void addListener(void Function(CustomerInfo info) listener) {
    if (!_initialized) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }
}
