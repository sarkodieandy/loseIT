import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';

class PremiumGate extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return child;

    void openPaywall() {
      if (onUpgrade != null) {
        onUpgrade!.call();
        return;
      }
      // Best-effort: route exists in app router.
      try {
        context.push('/paywall');
      } catch (_) {}
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.22),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colorScheme.primary.withValues(alpha: 0.16),
                colorScheme.secondary.withValues(alpha: 0.10),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock,
                size: 28,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 10),
              Text(
                lockedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                lockedDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 46,
                child: FilledButton(
                  onPressed: openPaywall,
                  child: const Text('Go Premium'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
