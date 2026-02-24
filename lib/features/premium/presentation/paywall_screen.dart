import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../providers/app_providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSnack = false}) async {
    setState(() => _loading = true);
    try {
      _offerings = await RevenueCatService.instance.fetchOfferings();
    } catch (error, stackTrace) {
      AppLogger.error('paywall.load', error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load offerings: ${error.toString()}')),
        );
      }
      _offerings = null;
    }
    if (mounted) {
      setState(() => _loading = false);
    }
    if (_offerings == null) {
      AppLogger.warn('paywall.load: Offerings returned null (no offerings)');
    } else {
      final offeringId = _offerings?.current?.identifier ?? 'none';
      final packages = _offerings?.current?.availablePackages ?? <Package>[];
      AppLogger.info(
          'paywall.load: offering=$offeringId, packages=${packages.length}');
      for (final p in packages) {
        final prod = p.storeProduct;
        AppLogger.info(
            'paywall.package: id=${p.identifier}, product=${prod.identifier}, price=${prod.priceString}');
      }
      if (packages.isEmpty) {
        AppLogger.warn(
            'paywall.load: No packages attached to offering $offeringId');
      }
    }

    if (showSnack && mounted) {
      final offeringId = _offerings?.current?.identifier ?? 'none';
      final packageCount = _offerings?.current?.availablePackages.length ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Offering: $offeringId • packages=$packageCount')),
      );
    }
  }

  Future<void> _purchase(Package package) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      final info = await RevenueCatService.instance.purchase(package);
      if (info != null && RevenueCatService.instance.isPremiumFrom(info)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium unlocked.')),
        );
        context.pop();
      }
    } catch (error, stackTrace) {
      AppLogger.error('paywall.purchase', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _purchasing = true);
    try {
      final info = await RevenueCatService.instance.restorePurchases();
      if (!mounted) return;
      final isPremium =
          info != null && RevenueCatService.instance.isPremiumFrom(info);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPremium ? 'Purchases restored.' : 'No active subscription found.',
          ),
        ),
      );
      if (isPremium) context.pop();
    } catch (error, stackTrace) {
      AppLogger.error('paywall.restore', error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(premiumControllerProvider);
    final configured = RevenueCatService.instance.isConfigured;

    final offering = _offerings?.current;
    final packages = offering?.availablePackages ?? const <Package>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
        leading: IconButton(
          tooltip: 'Close',
          onPressed: _purchasing
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
          icon: const Icon(Icons.close),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh offerings',
            onPressed: _purchasing ? null : () => _load(showSnack: true),
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: _purchasing ? null : _restore,
            child: const Text('Restore'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.18),
                        Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Be Sober Premium',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.auto_graph,
                        text: 'Weekly insights & personalized trends',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.playlist_add_check,
                        text: 'Track unlimited habits with detailed stats',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.mic,
                        text: 'Voice journaling with AI transcription',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.group,
                        text: 'Community support & custom milestones',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.not_interested,
                        text: 'Ad‑free experience',
                      ),
                      const SizedBox(height: 8),
                      const _BenefitRow(
                        icon: Icons.support_agent,
                        text: 'Priority customer support',
                      ),
                      const SizedBox(height: 10),
                      if (status.isPremium)
                        Text(
                          'You\'re premium.',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        )
                      else if (status.isTrialActive)
                        Text(
                          'Trial active (${status.trialDaysRemaining} days left)',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        )
                      else
                        Text(
                          'Your 3‑day trial has ended.',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Production: clean header information
                if (_offerings != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Unlock all premium features with one of our plans.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                if (!configured)
                  const _WarningCard(
                    title: 'RevenueCat not configured',
                    message:
                        'Add REVENUECAT_IOS_API_KEY to .env, then run again.',
                  )
                else if (packages.isEmpty) ...[
                  const _WarningCard(
                    title: 'No products found',
                    message:
                        'Configure an Offering in RevenueCat and attach packages.',
                  ),
                ] else ...[
                  ...packages.map((p) => _PackageTile(
                        package: p,
                        purchasing: _purchasing,
                        onTap: () => _purchase(p),
                      )),
                ],

                const SizedBox(height: 18),
                Text(
                  'Cancel anytime in App Store settings.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.purchasing,
    required this.onTap,
  });

  final Package package;
  final bool purchasing;
  final VoidCallback onTap;

  String _titleFor(PackageType type) {
    return switch (type) {
      PackageType.weekly => 'Weekly',
      PackageType.monthly => 'Monthly',
      PackageType.twoMonth => 'Every 2 months',
      PackageType.threeMonth => 'Every 3 months',
      PackageType.sixMonth => 'Every 6 months',
      PackageType.annual => 'Yearly',
      PackageType.lifetime => 'Lifetime',
      _ => 'Premium',
    };
  }

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final title = _titleFor(package.packageType);
    final price = product.priceString;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: purchasing ? null : onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                price,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
