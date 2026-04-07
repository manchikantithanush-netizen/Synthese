import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:cupertino_native/cupertino_native.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  const PremiumButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: isLoading
            ? Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.white : Colors.black,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : CNButton(
                label: text,
                style: CNButtonStyle.prominentGlass,
                tint: color ?? (isDark ? Colors.white : Colors.black),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
              ),
      ),
    );
  }
}