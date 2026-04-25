import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global accent color and theme mode used across the app.
class AccentColor {
  AccentColor._();

  static const Color _defaultColor = Color(0xFFCB6B8A);
  static const String _prefKey = 'accent_color_value';
  static const String _themePrefKey = 'theme_mode_value';

  static final ValueNotifier<Color> notifier =
      ValueNotifier<Color>(_defaultColor);

  static final ValueNotifier<ThemeMode> themeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Call once at app start.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_prefKey);
    if (stored != null) notifier.value = Color(stored);

    final storedTheme = prefs.getString(_themePrefKey);
    if (storedTheme == 'light') themeNotifier.value = ThemeMode.light;
    else if (storedTheme == 'dark') themeNotifier.value = ThemeMode.dark;
    else themeNotifier.value = ThemeMode.system;
  }

  static Future<void> set(Color color) async {
    notifier.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, color.value);
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    final val = mode == ThemeMode.light ? 'light'
               : mode == ThemeMode.dark ? 'dark'
               : 'system';
    await prefs.setString(_themePrefKey, val);
  }

  /// Preset swatches shown in the picker.
  static const List<({String label, Color color})> presets = [
    (label: 'Coral Rose', color: Color(0xFFCB6B8A)),
    (label: 'Violet', color: Color(0xFF7C5CBF)),
    (label: 'Sky Blue', color: Color(0xFF4A90D9)),
    (label: 'Teal', color: Color(0xFF2ABFBF)),
    (label: 'Sage', color: Color(0xFF6BAF7A)),
    (label: 'Amber', color: Color(0xFFD4882A)),
    (label: 'Crimson', color: Color(0xFFD94F4F)),
    (label: 'Slate', color: Color(0xFF6B7FA3)),
  ];
}
