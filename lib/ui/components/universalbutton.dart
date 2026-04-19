import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:synthese/ui/components/bouncing_dots_loader.dart';

class UniversalButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final double height;
  final double borderRadius;

  const UniversalButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.height = 48,
    this.borderRadius = 50,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = color ?? (isDark ? Colors.white : Colors.black);
    final foregroundColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.35),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          side: BorderSide.none,
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 44,
                child: BouncingDotsLoader.compact(color: foregroundColor),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

class PremiumButton extends UniversalButton {
  const PremiumButton({
    super.key,
    required super.text,
    required super.onPressed,
    super.isLoading,
    super.color,
  });
}
