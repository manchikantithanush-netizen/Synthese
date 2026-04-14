import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UniversalBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final bool isForwardArrow;

  const UniversalBackButton({
    super.key,
    required this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.size = 40,
    this.isForwardArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor =
        iconColor ?? (isDark ? Colors.white : Colors.black);
    final effectiveBackground =
        backgroundColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.06));
    final effectiveBorder =
        borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.08));

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: effectiveBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size / 2),
          side: BorderSide(color: effectiveBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Center(
            child: Icon(
              isForwardArrow 
                ? Icons.arrow_forward_ios_rounded
                : Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: effectiveIconColor,
            ),
          ),
        ),
      ),
    );
  }
}
