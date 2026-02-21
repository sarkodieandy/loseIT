import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/widgets/app_buttons.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offering? _offering;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final offerings = await Purchases.getOfferings();
      setState(() {
        _offering = offerings.current;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _purchase(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Go Premium')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _offering == null
              ? const Center(child: Text('No offers available.'))
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Unlock all premium features.',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._offering!.availablePackages.map((package) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PrimaryButton(
                            label:
                                '${package.storeProduct.title} • ${package.storeProduct.priceString}',
                            onPressed: () => _purchase(package),
                          ),
                        );
                      }),
                      const Spacer(),
                      SecondaryButton(
                        label: 'Restore purchases',
                        onPressed: () async {
                          try {
                            await Purchases.restorePurchases();
                            if (!mounted) return;
                            Navigator.of(context).pop(true);
                          } catch (error) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
    );
  }
}
