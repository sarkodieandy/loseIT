import 'package:flutter/material.dart';

class UnreadDot extends StatelessWidget {
  const UnreadDot({
    super.key,
    this.size = 10,
    this.color = const Color(0xFFE05555),
    this.borderColor,
    this.borderWidth = 2,
  });

  final double size;
  final Color color;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth,
        ),
      ),
    );
  }
}

