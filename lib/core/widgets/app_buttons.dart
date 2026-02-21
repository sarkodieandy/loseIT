import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    final style = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );

    final handler = (isLoading || onPressed == null)
        ? null
        : () {
            HapticFeedback.selectionClick();
            onPressed?.call();
          };

    if (icon == null) {
      return ElevatedButton(
        onPressed: handler,
        style: style,
        child: child,
      );
    }

    return ElevatedButton.icon(
      onPressed: handler,
      icon: Icon(icon),
      label: child,
      style: style,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );

    final handler = onPressed == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            onPressed?.call();
          };

    if (icon == null) {
      return OutlinedButton(
        onPressed: handler,
        style: style,
        child: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: handler,
      icon: Icon(icon),
      label: Text(label),
      style: style,
    );
  }
}
