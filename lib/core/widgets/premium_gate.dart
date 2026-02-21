import 'package:flutter/material.dart';

class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.child,
    this.lockedTitle = 'Premium Feature',
    this.lockedDescription = 'Upgrade to unlock this feature.',
    this.onUpgrade,
  });

  final Widget child;
  final String lockedTitle;
  final String lockedDescription;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
