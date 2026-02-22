import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/utils/app_logger.dart';

class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  final StreamController<CustomerInfo> _customerInfoController =
      StreamController<CustomerInfo>.broadcast();

  bool _configured = false;
  String _entitlementId = 'premium';
  CustomerInfo? _lastCustomerInfo;

  bool get isConfigured => _configured;
  String get entitlementId => _entitlementId;
  CustomerInfo? get lastCustomerInfo => _lastCustomerInfo;

  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  Future<void> initialize({
    required String apiKey,
    String entitlementId = 'premium',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      AppLogger.warn('RevenueCat: missing API key, skipping initialization');
      return;
    }

    _entitlementId = entitlementId.trim().isEmpty ? 'premium' : entitlementId;

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      await Purchases.configure(PurchasesConfiguration(trimmedKey));

      Purchases.addCustomerInfoUpdateListener((info) {
        _lastCustomerInfo = info;
        if (!_customerInfoController.isClosed) {
          _customerInfoController.add(info);
        }
      });

      _configured = true;
      AppLogger.info('RevenueCat: configured entitlement=$_entitlementId');

      // Emit initial state.
      final info = await Purchases.getCustomerInfo();
      _lastCustomerInfo = info;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(info);
      }
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.initialize', error, stackTrace);
    }
  }

  bool isPremiumFrom(CustomerInfo info) {
    final active = info.entitlements.active;
    return active.containsKey(_entitlementId);
  }

  Future<bool> isPremium() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      _lastCustomerInfo = info;
      return isPremiumFrom(info);
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.isPremium', error, stackTrace);
      return false;
    }
  }

  Future<void> syncUser(String? appUserId) async {
    if (!_configured) return;

    try {
      final trimmed = appUserId?.trim();
      if (trimmed == null || trimmed.isEmpty) {
        AppLogger.info('RevenueCat: logOut');
        final info = await Purchases.logOut();
        _lastCustomerInfo = info;
        if (!_customerInfoController.isClosed) {
          _customerInfoController.add(info);
        }
        return;
      }

      AppLogger.info('RevenueCat: logIn userId=$trimmed');
      final result = await Purchases.logIn(trimmed);
      _lastCustomerInfo = result.customerInfo;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(result.customerInfo);
      }
      AppLogger.info('RevenueCat: logIn created=${result.created}');
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.syncUser', error, stackTrace);
    }
  }

  Future<Offerings?> fetchOfferings() async {
    if (!_configured) return null;
    try {
      return Purchases.getOfferings();
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.offerings', error, stackTrace);
      return null;
    }
  }

  Future<CustomerInfo?> purchase(Package package) async {
    if (!_configured) return null;
    try {
      final info = await Purchases.purchasePackage(package);
      _lastCustomerInfo = info;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(info);
      }
      return info;
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error('revenuecat.purchase', error, stackTrace);
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.purchase', error, stackTrace);
      return null;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_configured) return null;
    try {
      final info = await Purchases.restorePurchases();
      _lastCustomerInfo = info;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(info);
      }
      return info;
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.restore', error, stackTrace);
      return null;
    }
  }
}
