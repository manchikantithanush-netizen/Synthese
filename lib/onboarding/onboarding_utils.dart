import 'package:flutter/material.dart';

class OnboardingUtils {
  // Common Input Decoration for all steps (Added BuildContext for Dynamic Theming)
  static InputDecoration iosInput(BuildContext context, String hint, IconData icon) {
    // DYNAMIC THEME VARIABLE
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
      prefixIcon: Icon(icon, color: const Color(0xFF8E8E93), size: 20),
      filled: true,
      // DYNAMIC: Dark gray in dark mode, light gray in light mode
      fillColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50), 
        borderSide: BorderSide.none,
      ),
    );
  }
}