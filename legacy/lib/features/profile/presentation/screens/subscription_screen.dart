import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app_controller.dart';
import '../../../../core/theme/discipline_colors.dart';
import '../../../../core/theme/discipline_text_styles.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/discipline_button.dart';
import '../../../../core/widgets/discipline_card.dart';
import '../../../../core/widgets/discipline_scaffold.dart';
import '../../../../services/store/revenuecat_store.dart';
import '../../../../services/store/store_subscription_config.dart';

enum _Plan { monthly, yearly }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loadingStore = true;
  bool _storeAvailable = false;
  bool _purchaseInProgress = false;
  bool _restoreInProgress = false;
  String? _storeMessage;

  CustomerInfo? _customerInfo;
  Package? _monthlyPackage;
  Package? _yearlyPackage;
  _Plan _selectedPlan = _Plan.yearly;

  Package? get _selectedPackage {
    return switch (_selectedPlan) {
      _Plan.monthly => _monthlyPackage,
      _Plan.yearly => _yearlyPackage,
    };
  }

  bool get _canPurchase {
    return _storeAvailable &&
        !_loadingStore &&
        !_purchaseInProgress &&
        _selectedPackage != null;
  }

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Offering? _selectOffering(Offerings offerings, {String? desiredOfferingId}) {
    final desired = desiredOfferingId?.trim() ?? '';
    if (desired.isNotEmpty) {
      return offerings.getOffering(desired) ?? offerings.current;
    }
    return offerings.current;
  }

  Package? _monthlyFromOffering(Offering offering) {
    return offering.monthly ??
        offering.availablePackages.firstWhereOrNull(
          (p) => p.packageType == PackageType.monthly,
        ) ??
        offering.availablePackages.firstWhereOrNull(
          (p) =>
              p.storeProduct.identifier ==
              StoreSubscriptionConfig.monthlyProductId,
        );
  }

  Package? _yearlyFromOffering(Offering offering) {
    return offering.annual ??
        offering.availablePackages.firstWhereOrNull(
          (p) => p.packageType == PackageType.annual,
        ) ??
        offering.availablePackages.firstWhereOrNull(
          (p) =>
              p.storeProduct.identifier ==
              StoreSubscriptionConfig.yearlyProductId,
        );
  }

  Future<void> _loadStore() async {
    setState(() {
      _loadingStore = true;
      _storeMessage = null;
    });

    try {
      final app = AppScope.of(context);
      final userId = app.services.auth.currentUserId;
      final desiredOfferingId =
          StoreSubscriptionConfig.revenueCatOfferingId.trim();

      final configured = await RevenueCatStore.instance.configureIfNeeded(
        appUserId: userId,
      );
      if (!mounted) return;

      if (!configured) {
        setState(() {
          _storeAvailable = false;
          _loadingStore = false;
          _storeMessage =
              'RevenueCat is not configured for this build. Add REVENUECAT_IOS_API_KEY / REVENUECAT_ANDROID_API_KEY.';
        });
        return;
      }

      final offerings = await RevenueCatStore.instance.getOfferings(
        appUserId: userId,
      );
      final customerInfo = await RevenueCatStore.instance.getCustomerInfo(
        appUserId: userId,
      );
      if (!mounted) return;

      if (offerings == null) {
        setState(() {
          _storeAvailable = false;
          _loadingStore = false;
          _storeMessage = 'Unable to load subscription products.';
        });
        return;
      }

      final offering = _selectOffering(
        offerings,
        desiredOfferingId: desiredOfferingId,
      );

      final monthly = offering == null ? null : _monthlyFromOffering(offering);
      final yearly = offering == null ? null : _yearlyFromOffering(offering);

      String? message;
      if (desiredOfferingId.isNotEmpty &&
          offerings.getOffering(desiredOfferingId) == null &&
          offering != null) {
        message =
            'Offering "$desiredOfferingId" not found. Showing current offering "${offering.identifier}".';
      }
      if (offering == null) {
        message =
            'No RevenueCat offering configured for this build. Publish an offering and attach packages.';
      } else if (monthly == null && yearly == null) {
        message =
            'No subscription packages found. Add monthly/annual packages in RevenueCat offering "${offering.identifier}".';
      }

      var selected = _selectedPlan;
      if (selected == _Plan.yearly && yearly == null && monthly != null) {
        selected = _Plan.monthly;
      }
      if (selected == _Plan.monthly && monthly == null && yearly != null) {
        selected = _Plan.yearly;
      }

      setState(() {
        _storeAvailable = offering != null;
        _loadingStore = false;
        _customerInfo = customerInfo;
        _monthlyPackage = monthly;
        _yearlyPackage = yearly;
        _selectedPlan = selected;
        _storeMessage = (message == null || message.isEmpty) ? null : message;
      });
    } catch (error, stackTrace) {
      AppLogger.error('SubscriptionScreen._loadStore', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _storeAvailable = false;
        _loadingStore = false;
        _storeMessage = _friendlyStoreMessage(error);
      });
    }
  }

  Future<void> _buySelectedPlan() async {
    final selectedPackage = _selectedPackage;
    if (selectedPackage == null || _purchaseInProgress) {
      return;
    }

    setState(() {
      _purchaseInProgress = true;
      _storeMessage = null;
    });

    final app = AppScope.of(context);

    try {
      final customerInfo = await RevenueCatStore.instance.purchasePackage(
        selectedPackage,
        appUserId: app.services.auth.currentUserId,
      );
      final isPremium = RevenueCatStore.instance.isPremium(customerInfo);
      final expiresAt = RevenueCatStore.instance.premiumExpiresAt(customerInfo);
      await app.setPremium(isPremium);
      if (!mounted) return;

      final expiryText = _formatExpiry(expiresAt);
      setState(() {
        _purchaseInProgress = false;
        _customerInfo = customerInfo;
        if (isPremium) {
          _storeMessage = expiryText == null
              ? 'Premium subscription is active.'
              : 'Premium active until $expiryText.';
        } else {
          _storeMessage =
              'Purchase received, but no active premium entitlement was found.';
        }
      });
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error(
        'SubscriptionScreen._buySelectedPlan.platform',
        error,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _purchaseInProgress = false;
        _storeMessage = _friendlyStoreMessage(error);
      });
    } catch (error, stackTrace) {
      AppLogger.error('SubscriptionScreen._buySelectedPlan', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _purchaseInProgress = false;
        _storeMessage = _friendlyStoreMessage(error);
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (_restoreInProgress || !_storeAvailable) return;

    setState(() {
      _restoreInProgress = true;
      _storeMessage = null;
    });

    final app = AppScope.of(context);

    try {
      final customerInfo = await RevenueCatStore.instance.restorePurchases(
        appUserId: app.services.auth.currentUserId,
      );
      if (!mounted) return;

      if (customerInfo == null) {
        setState(() {
          _storeMessage = 'Unable to restore purchases right now.';
        });
        return;
      }

      final isPremium = RevenueCatStore.instance.isPremium(customerInfo);
      final expiresAt = RevenueCatStore.instance.premiumExpiresAt(customerInfo);
      await app.setPremium(isPremium);
      if (!mounted) return;

      final expiryText = _formatExpiry(expiresAt);
      setState(() {
        _customerInfo = customerInfo;
        if (isPremium) {
          _storeMessage = expiryText == null
              ? 'Premium subscription restored.'
              : 'Premium restored until $expiryText.';
        } else {
          _storeMessage =
            'No active premium entitlement found for this Apple/Google account.';
        }
      });
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error(
        'SubscriptionScreen._restorePurchases.platform',
        error,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _storeMessage = _friendlyStoreMessage(error);
      });
    } catch (error, stackTrace) {
      AppLogger.error('SubscriptionScreen._restorePurchases', error, stackTrace);
      if (!mounted) return;
      setState(() {
        _storeMessage = _friendlyStoreMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _restoreInProgress = false;
        });
      }
    }
  }

  String? _formatExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return null;
    final local = expiresAt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$year-$month-$day';
  }

  String _planPrice(_Plan plan) {
    final package = switch (plan) {
      _Plan.monthly => _monthlyPackage,
      _Plan.yearly => _yearlyPackage,
    };
    if (package != null) {
      final suffix = switch (plan) {
        _Plan.monthly => ' / month',
        _Plan.yearly => ' / year',
      };
      return '${package.storeProduct.priceString}$suffix';
    }
    return switch (plan) {
      _Plan.monthly => '\$9.99 / month',
      _Plan.yearly => '\$59.99 / year',
    };
  }

  String _friendlyStoreMessage(Object error) {
    if (error is PlatformException) {
      try {
        final code = PurchasesErrorHelper.getErrorCode(error);
        if (code == PurchasesErrorCode.purchaseCancelledError) {
          return 'Purchase canceled.';
        }
        if (code == PurchasesErrorCode.networkError ||
            code == PurchasesErrorCode.offlineConnectionError) {
          return 'Network unavailable. Check internet and try again.';
        }
        if (code == PurchasesErrorCode.storeProblemError ||
            code == PurchasesErrorCode.productRequestTimeout) {
          return 'Store connection failed. Try again in a moment.';
        }
        if (code == PurchasesErrorCode.configurationError) {
          return 'RevenueCat configuration error. Check offering/products setup.';
        }
        final raw = error.message?.trim();
        if (raw != null && raw.isNotEmpty) return raw;
      } catch (_) {
        // Fall back to generic parsing below.
      }
    }

    final text = error.toString().trim();
    final lower = text.toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('socketexception') ||
        lower.contains('network')) {
      return 'Network unavailable. Check internet and try again.';
    }
    if (text.isEmpty) {
      return 'Subscription request failed. Please try again.';
    }
    return text;
  }

  Future<void> _openManageSubscription() async {
    final customerInfo = _customerInfo;
    final url = customerInfo == null
        ? null
        : RevenueCatStore.instance.managementUrl(customerInfo);

    if (url == null) {
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Manage subscription'),
          content: const Text(
            'Open iPhone Settings → Apple ID → Subscriptions to manage or cancel.',
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      setState(() => _storeMessage = 'Invalid subscription management link.');
      return;
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        setState(
          () => _storeMessage = 'Unable to open subscription management page.',
        );
      }
    } catch (error, stackTrace) {
      AppLogger.error(
        'SubscriptionScreen._openManageSubscription',
        error,
        stackTrace,
      );
      if (!mounted) return;
      setState(
        () => _storeMessage = 'Unable to open subscription management page.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final premium = app.state.isPremium;
        final hasManageUrl = _customerInfo != null &&
            RevenueCatStore.instance.managementUrl(_customerInfo!) != null;

        Widget planCard({
          required String title,
          required String price,
          required List<String> features,
          required bool highlighted,
          String? badge,
          VoidCallback? onTap,
        }) {
          return DisciplineCard(
            onTap: onTap,
            borderColor: highlighted ? DisciplineColors.accent : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(title, style: DisciplineTextStyles.section),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: DisciplineColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: DisciplineColors.accent.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: DisciplineTextStyles.caption.copyWith(
                            color: DisciplineColors.accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: DisciplineTextStyles.title.copyWith(
                    fontWeight: FontWeight.w800,
                    color: highlighted
                        ? DisciplineColors.accent
                        : DisciplineColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.checkmark,
                          size: 16,
                          color: highlighted
                              ? DisciplineColors.accent
                              : DisciplineColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            f,
                            style: DisciplineTextStyles.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return DisciplineScaffold(
          title: 'Subscription',
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 18),
            children: <Widget>[
              const Text('Plan control.', style: DisciplineTextStyles.title),
              const SizedBox(height: 10),
              Text(
                'Upgrade for relapse prediction, advanced analytics, and private chat.',
                style: DisciplineTextStyles.secondary.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 18),
              planCard(
                title: 'Standard',
                price: '\$0',
                highlighted: false,
                features: const <String>[
                  'Dashboard',
                  'Emergency flow',
                  'Basic analytics',
                ],
              ),
              const SizedBox(height: 14),
              planCard(
                title: 'Premium Monthly',
                price: _planPrice(_Plan.monthly),
                highlighted: _selectedPlan == _Plan.monthly,
                features: const <String>[
                  'AI relapse prediction',
                  'Unlimited emergency support',
                  'Lock Mode protection',
                  'Advanced analytics',
                  'Anonymous private chat',
                ],
                onTap: _monthlyPackage == null
                    ? null
                    : () => setState(() => _selectedPlan = _Plan.monthly),
              ),
              const SizedBox(height: 12),
              planCard(
                title: 'Premium Yearly',
                price: _planPrice(_Plan.yearly),
                badge: 'Best Value',
                highlighted: _selectedPlan == _Plan.yearly,
                features: const <String>[
                  'AI relapse prediction',
                  'Unlimited emergency support',
                  'Lock Mode protection',
                  'Advanced analytics',
                  'Anonymous private chat',
                ],
                onTap: _yearlyPackage == null
                    ? null
                    : () => setState(() => _selectedPlan = _Plan.yearly),
              ),
              if (_storeMessage != null) ...[
                const SizedBox(height: 12),
                DisciplineCard(
                  shadow: false,
                  borderColor: _storeAvailable
                      ? DisciplineColors.border.withValues(alpha: 0.75)
                      : DisciplineColors.danger.withValues(alpha: 0.5),
                  color: _storeAvailable
                      ? DisciplineColors.surface2.withValues(alpha: 0.7)
                      : DisciplineColors.danger.withValues(alpha: 0.12),
                  child: Text(
                    _storeMessage!,
                    style: DisciplineTextStyles.caption.copyWith(
                      color: _storeAvailable
                          ? DisciplineColors.textSecondary
                          : DisciplineColors.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              DisciplineButton(
                label: premium
                    ? 'Premium Active'
                    : _loadingStore
                        ? 'Loading subscription…'
                        : _purchaseInProgress
                            ? 'Opening store…'
                            : _selectedPackage != null
                                ? 'Subscribe ${_selectedPackage!.storeProduct.priceString}'
                                : 'Subscription unavailable',
                onPressed: premium || !_canPurchase ? null : _buySelectedPlan,
              ),
              const SizedBox(height: 12),
              DisciplineButton(
                label: _restoreInProgress ? 'Restoring…' : 'Restore Purchases',
                variant: DisciplineButtonVariant.secondary,
                onPressed:
                    _loadingStore || !_storeAvailable || _restoreInProgress
                        ? null
                        : _restorePurchases,
              ),
              const SizedBox(height: 12),
              if (premium || hasManageUrl)
                DisciplineButton(
                  label: 'Manage subscription',
                  variant: DisciplineButtonVariant.secondary,
                  onPressed: _openManageSubscription,
                ),
            ],
          ),
        );
      },
    );
  }
}
