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

    // Basic validation: server keys start with `sk_` and should not be
    // used in the client SDK. Warn and skip initialization if that's the case.
    if (trimmedKey.startsWith('sk_') || trimmedKey.startsWith('sk-')) {
      AppLogger.error(
        'revenuecat.initialize',
        'Provided API key looks like a server key (sk_). Skipping initialization to avoid misuse.',
      );
      return;
    }

    _entitlementId = _normalizeEntitlementId(entitlementId);

    try {
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      // Mask key for logs (avoid printing full secret)
      final masked = trimmedKey.length > 8
          ? '${trimmedKey.substring(0, 4)}...${trimmedKey.substring(trimmedKey.length - 4)}'
          : '***';
      AppLogger.info('RevenueCat: configuring with key=$masked');

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

  /// Start 3-day trial
  Future<bool> startTrial() async {
    if (!_configured) return false;
    try {
      AppLogger.info('revenuecat: starting 3-day trial');
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

      // avoid unnecessary logout calls; the decodeEnvelope error was seen when
      // calling logOut repeatedly or when the SDK was not in a valid state.
      // use the provided future getter; avoids undefined method error
      final currentId = await Purchases.appUserID;

      bool _isAnonymous(String id) => id.startsWith(r'$RCAnonymousID');

      if (trimmed == null || trimmed.isEmpty) {
        if (currentId.isEmpty || _isAnonymous(currentId)) {
          AppLogger.info(
              'RevenueCat: already logged out or anonymous ($currentId), skipping');
          return;
        }

        AppLogger.info('RevenueCat: logOut');
        try {
          final info = await Purchases.logOut();
          _lastCustomerInfo = info;
          if (!_customerInfoController.isClosed) {
            _customerInfoController.add(info);
          }
          AppLogger.info('RevenueCat: logOut completed successfully');
        } on PlatformException catch (pe) {
          AppLogger.error('revenuecat.syncUser', pe);
          // ignore; logout not critical
        }
        return;
      }

      // if already logged in as desired user, nothing to do
      if (trimmed == currentId) {
        AppLogger.info('RevenueCat: syncUser no-op (already logged in)');
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
      // Try a normal fetch first (may return a cached value). If packages
      // are empty, attempt a forced refresh to pick up new offerings.
      var offerings = await Purchases.getOfferings();
      var packages = offerings.current?.availablePackages ?? <Package>[];
      var packageCount = packages.length;

      if (packageCount == 0) {
        AppLogger.warn(
            'revenuecat: no packages found in cached offerings, forcing refresh');
        try {
          // The purchases_flutter version in use doesn't support a named
          // `forceRefresh` parameter. Request offerings again which may
          // refresh cached values.
          offerings = await Purchases.getOfferings();
          packages = offerings.current?.availablePackages ?? <Package>[];
          packageCount = packages.length;
        } catch (e, st) {
          AppLogger.error('revenuecat.offerings.refresh', e, st);
        }
      }

      final offeringId = offerings.current?.identifier ?? 'none';
      AppLogger.info(
          'revenuecat: offering=$offeringId, packages=$packageCount');

      // Log details for easier debugging when packages are present
      for (final p in packages) {
        final prod = p.storeProduct;
        AppLogger.info(
            'revenuecat.package: id=${p.identifier}, type=${p.packageType}, productId=${prod.identifier}, price=${prod.priceString}');
      }

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
