import 'package:flutter/material.dart';

class UniversalResetButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const UniversalResetButton({
    super.key,
    required this.onPressed,
    this.size = 40,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = backgroundColor ?? 
      (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08));
    
    final iColor = iconColor ?? 
      (isDark ? Colors.white : Colors.black);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.refresh_rounded,
            size: size * 0.5,
            color: iColor,
          ),
        ),
      ),
    );
  }
}
