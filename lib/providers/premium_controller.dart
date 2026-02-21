import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../data/services/revenuecat_service.dart';

class PremiumController extends StateNotifier<bool> {
  PremiumController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final status = await RevenueCatService.instance.isPremium();
    if (!mounted) return;
    state = status;
    RevenueCatService.instance.addListener(_onInfo);
  }

  void _onInfo(CustomerInfo info) {
    if (!mounted) return;
    state = info.entitlements.active.containsKey('premium');
  }
}
