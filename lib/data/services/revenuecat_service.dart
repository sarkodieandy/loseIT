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

    _entitlementId = _normalizeEntitlementId(entitlementId);

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      await Purchases.configure(PurchasesConfiguration(trimmedKey));

      Purchases.addCustomerInfoUpdateListener(
        (info) {
          try {
            _lastCustomerInfo = info;
            if (!_customerInfoController.isClosed) {
              _customerInfoController.add(info);
            }
            AppLogger.info('revenuecat: customer info updated');
          } catch (error, stackTrace) {
            AppLogger.error('revenuecat.listener', error, stackTrace);
          }
        },
      );

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

  static String _normalizeEntitlementId(String value) {
    var trimmed = value.trim();
    if (trimmed.isEmpty) return 'premium';

    // Allow `.env` to use quotes for values with spaces, like:
    // REVENUECAT_ENTITLEMENT_ID="Be Sober Pro"
    if (trimmed.length >= 2) {
      final first = trimmed.codeUnitAt(0);
      final last = trimmed.codeUnitAt(trimmed.length - 1);
      final isDoubleQuoted = first == 34 && last == 34; // "
      final isSingleQuoted = first == 39 && last == 39; // '
      if (isDoubleQuoted || isSingleQuoted) {
        trimmed = trimmed.substring(1, trimmed.length - 1).trim();
      }
    }

    return trimmed.isEmpty ? 'premium' : trimmed;
  }

  bool isPremiumFrom(CustomerInfo info) {
    final active = info.entitlements.active;
    return active.containsKey(_entitlementId);
  }

  /// Check if trial is still active
  bool isTrialActive(DateTime? trialEndsAt) {
    if (trialEndsAt == null) return false;
    return DateTime.now().isBefore(trialEndsAt);
  }

  /// Get trial days remaining
  int getTrialDaysRemaining(DateTime? trialEndsAt) {
    if (trialEndsAt == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(trialEndsAt)) return 0;
    return trialEndsAt.difference(now).inDays + 1;
  }

  /// Start 7-day trial
  Future<bool> startTrial() async {
    if (!_configured) return false;
    try {
      AppLogger.info('revenuecat: starting 7-day trial');
      // Trial is tracked in Supabase profiles table
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.startTrial', error, stackTrace);
      return false;
    }
  }

  Future<bool> isPremium() async {
    if (!_configured) return false;
    try {
      final info = await Purchases.getCustomerInfo();
      _lastCustomerInfo = info;
      final premium = isPremiumFrom(info);
      AppLogger.info(
          'revenuecat: isPremium=$premium, entitlements=${info.entitlements.active.keys}');
      return premium;
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
        AppLogger.info('RevenueCat: logOut completed successfully');
        return;
      }

      AppLogger.info('RevenueCat: logIn userId=$trimmed');
      final result = await Purchases.logIn(trimmed);
      _lastCustomerInfo = result.customerInfo;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(result.customerInfo);
      }
      final premium = isPremiumFrom(result.customerInfo);
      AppLogger.info(
          'RevenueCat: logIn created=${result.created}, premium=$premium');
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.syncUser', error, stackTrace);
    }
  }

  Future<Offerings?> fetchOfferings() async {
    if (!_configured) return null;
    try {
      final offerings = await Purchases.getOfferings();
      final offeringId = offerings.current?.identifier ?? 'none';
      final packageCount = offerings.current?.availablePackages.length ?? 0;
      AppLogger.info(
          'revenuecat: offering=$offeringId, packages=$packageCount');
      return offerings;
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.offerings', error, stackTrace);
      return null;
    }
  }

  Future<CustomerInfo?> purchase(Package package) async {
    if (!_configured) return null;
    try {
      AppLogger.info('revenuecat: purchasing ${package.identifier}');
      final info = await Purchases.purchasePackage(package);
      _lastCustomerInfo = info;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(info);
      }
      final premium = isPremiumFrom(info);
      AppLogger.info(
          'revenuecat: purchase success ${package.identifier}, premium=$premium');
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
      AppLogger.info('revenuecat: restoring purchases');
      final info = await Purchases.restorePurchases();
      _lastCustomerInfo = info;
      if (!_customerInfoController.isClosed) {
        _customerInfoController.add(info);
      }
      final premium = isPremiumFrom(info);
      AppLogger.info('revenuecat: restore success, premium=$premium');
      return info;
    } catch (error, stackTrace) {
      AppLogger.error('revenuecat.restore', error, stackTrace);
      return null;
    }
  }
}
