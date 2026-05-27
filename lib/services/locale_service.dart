import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app locale. Mirrors the AccentColor pattern (ValueNotifier +
/// SharedPreferences) and additionally syncs to Firestore so the choice
/// follows the user across devices.
class LocaleService {
  LocaleService._();

  static const String _prefKey = 'app_locale';

  static const List<({Locale locale, String nativeLabel, String englishLabel})>
      languages = [
    (locale: Locale('en'), nativeLabel: 'English', englishLabel: 'English'),
    (locale: Locale('es'), nativeLabel: 'Español', englishLabel: 'Spanish'),
    (locale: Locale('ar'), nativeLabel: 'العربية', englishLabel: 'Arabic'),
    (locale: Locale('hi'), nativeLabel: 'हिन्दी', englishLabel: 'Hindi'),
    (locale: Locale('zh'), nativeLabel: '中文', englishLabel: 'Mandarin'),
  ];

  static List<Locale> get supportedLocales =>
      languages.map((l) => l.locale).toList();

  static const Locale _fallback = Locale('en');

  static final ValueNotifier<Locale> localeNotifier =
      ValueNotifier<Locale>(_fallback);

  /// Call once at app start (before runApp).
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null && _isSupported(stored)) {
      localeNotifier.value = Locale(stored);
      return;
    }
    // First launch: prefer the device locale if we support it, else English.
    final deviceLang =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    localeNotifier.value =
        _isSupported(deviceLang) ? Locale(deviceLang) : _fallback;
  }

  /// Persist locally + (best-effort) mirror to Firestore.
  static Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale.languageCode)) return;
    localeNotifier.value = locale;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {'language': locale.languageCode},
          SetOptions(merge: true),
        );
      } catch (_) {
        // Network failure is non-fatal; SharedPreferences is the source of truth.
      }
    }
  }

  /// Apply a language code coming from Firestore (e.g. on sign-in) without
  /// writing back to Firestore. Silently ignores unsupported codes.
  static Future<void> applyFromRemote(String code) async {
    if (!_isSupported(code) || code == localeNotifier.value.languageCode) {
      return;
    }
    localeNotifier.value = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  static bool _isSupported(String code) =>
      languages.any((l) => l.locale.languageCode == code);
}
