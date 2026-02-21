import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/utils/app_logger.dart';
import 'store_subscription_config.dart';

class RevenueCatStore {
  RevenueCatStore._();

  static final RevenueCatStore instance = RevenueCatStore._();

  Future<bool>? _configureTask;
  String? _activeAppUserId;

  String _apiKeyForPlatform() {
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        StoreSubscriptionConfig.revenueCatAppleApiKey.trim(),
      TargetPlatform.android =>
        StoreSubscriptionConfig.revenueCatGoogleApiKey.trim(),
      _ => '',
    };
  }

  Future<bool> _configure() async {
    final apiKey = _apiKeyForPlatform();
    if (apiKey.isEmpty) return false;

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }
      await Purchases.configure(PurchasesConfiguration(apiKey));
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('RevenueCatStore.configure', error, stackTrace);
      return false;
    }
  }

  Future<void> syncAppUserId(String? appUserId) async {
    final normalized = appUserId?.trim();
    final desired = (normalized == null || normalized.isEmpty) ? null : normalized;

    if (desired == _activeAppUserId) return;

    try {
      if (desired == null) {
        await Purchases.logOut();
      } else {
        await Purchases.logIn(desired);
      }
      _activeAppUserId = desired;
    } catch (error, stackTrace) {
      AppLogger.error('RevenueCatStore.syncAppUserId', error, stackTrace);
    }
  }

  Future<bool> configureIfNeeded({String? appUserId}) async {
    final configured = await (_configureTask ??= _configure());
    if (!configured) return false;
    await syncAppUserId(appUserId);
    return true;
  }

  Future<CustomerInfo?> getCustomerInfo({String? appUserId}) async {
    final configured = await configureIfNeeded(appUserId: appUserId);
    if (!configured) return null;

    try {
      return await Purchases.getCustomerInfo();
    } catch (error, stackTrace) {
      AppLogger.error('RevenueCatStore.getCustomerInfo', error, stackTrace);
      return null;
    }
  }

  Future<Offerings?> getOfferings({String? appUserId}) async {
    final configured = await configureIfNeeded(appUserId: appUserId);
    if (!configured) return null;

    try {
      return await Purchases.getOfferings();
    } catch (error, stackTrace) {
      AppLogger.error('RevenueCatStore.getOfferings', error, stackTrace);
      return null;
    }
  }

  Future<CustomerInfo> purchasePackage(
    Package package, {
    String? appUserId,
  }) async {
    final configured = await configureIfNeeded(appUserId: appUserId);
    if (!configured) {
      throw StateError(
        'RevenueCat is not configured for this build. Add REVENUECAT_IOS_API_KEY / REVENUECAT_ANDROID_API_KEY.',
      );
    }
    return Purchases.purchasePackage(package);
  }

  Future<CustomerInfo?> restorePurchases({String? appUserId}) async {
    final configured = await configureIfNeeded(appUserId: appUserId);
    if (!configured) return null;

    try {
      return await Purchases.restorePurchases();
    } catch (error, stackTrace) {
      AppLogger.error('RevenueCatStore.restorePurchases', error, stackTrace);
      return null;
    }
  }

  bool isPremium(CustomerInfo customerInfo) {
    final entitlementId =
        StoreSubscriptionConfig.revenueCatPremiumEntitlementId.trim();
    if (entitlementId.isEmpty) return false;
    return customerInfo.entitlements.active.containsKey(entitlementId);
  }

  DateTime? premiumExpiresAt(CustomerInfo customerInfo) {
    final entitlementId =
        StoreSubscriptionConfig.revenueCatPremiumEntitlementId.trim();
    if (entitlementId.isEmpty) return null;

    final entitlement = customerInfo.entitlements.active[entitlementId];
    final raw = entitlement?.expirationDate?.trim();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  String? managementUrl(CustomerInfo customerInfo) {
    final raw = customerInfo.managementURL?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  void addCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeCustomerInfoUpdateListener(CustomerInfoUpdateListener listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}
