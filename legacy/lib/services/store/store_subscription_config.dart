class StoreSubscriptionConfig {
  static const String monthlyProductId = String.fromEnvironment(
    'IAP_PREMIUM_MONTHLY_PRODUCT_ID',
    defaultValue: 'discipline_premium_monthly',
  );

  static const String yearlyProductId = String.fromEnvironment(
    'IAP_PREMIUM_YEARLY_PRODUCT_ID',
    defaultValue: 'discipline_premium_yearly',
  );

  static const String revenueCatAppleApiKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
    defaultValue: '',
  );

  static const String revenueCatGoogleApiKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
    defaultValue: '',
  );

  static const String revenueCatPremiumEntitlementId = String.fromEnvironment(
    'REVENUECAT_PREMIUM_ENTITLEMENT_ID',
    defaultValue: 'premium',
  );

  static const String revenueCatOfferingId = String.fromEnvironment(
    'REVENUECAT_OFFERING_ID',
    defaultValue: '',
  );

  static Set<String> get productIds {
    return <String>{
      monthlyProductId.trim(),
      yearlyProductId.trim(),
    }.where((id) => id.isNotEmpty).toSet();
  }
}
