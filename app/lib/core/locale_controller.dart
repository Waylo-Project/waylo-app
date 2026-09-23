import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

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
  /// else the first device language the app ships, else English — the same
  /// outcome as MaterialApp's locale resolution. For non-widget callers
  /// (geocoding, push registration) that need a plain code.
  String get resolvedLanguageCode {
    final shipped = {
      for (final l in AppLocalizations.supportedLocales) l.languageCode,
    };
    final chosen = value?.languageCode;
    if (chosen != null && shipped.contains(chosen)) return chosen;
    for (final device in WidgetsBinding.instance.platformDispatcher.locales) {
      if (shipped.contains(device.languageCode)) return device.languageCode;
    }
    return 'en';
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
