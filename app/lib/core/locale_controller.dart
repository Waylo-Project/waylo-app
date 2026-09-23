import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide language selection, persisted across launches.
///
/// `value == null` means "follow the device locale" (the default); a non-null
/// [Locale] is an explicit user choice. The single [instance] sits above
/// `MaterialApp`, which rebuilds when it changes (see `main.dart`).
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController._() : super(null);

  static final LocaleController instance = LocaleController._();

  static const _prefsKey = 'app_locale';

  /// Restore the saved choice. Call once before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && code.isNotEmpty) value = Locale(code);
  }

  /// The active UI language code as the app resolves it: an explicit choice,
  /// else the device language, falling back to English (the only other shipped
  /// locale). For non-widget callers (push registration) that need a plain code.
  String get resolvedLanguageCode {
    final override = value?.languageCode;
    if (override == 'ko' || override == 'en') return override!;
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return device == 'ko' ? 'ko' : 'en';
  }

  /// Set (or clear, with null = follow device) the language and persist it.
  Future<void> setLocale(Locale? locale) async {
    if (locale == value) return;
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
