import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/utils/app_logger.dart';
import '../data/services/revenuecat_service.dart';

class PremiumController extends StateNotifier<bool> {
  PremiumController(this._service) : super(false) {
    _init();
  }

  final RevenueCatService _service;
  StreamSubscription<CustomerInfo>? _sub;

  Future<void> _init() async {
    // No key configured: premium remains false.
    if (!_service.isConfigured) {
      state = false;
      return;
    }

    try {
      state = await _service.isPremium();
      _sub = _service.customerInfoStream.listen((info) {
        final value = _service.isPremiumFrom(info);
        if (mounted) state = value;
      });
    } catch (error, stackTrace) {
      AppLogger.error('premium.init', error, stackTrace);
      if (mounted) state = false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

