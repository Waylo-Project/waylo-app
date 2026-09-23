import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark selection, persisted across launches.
///
/// The value is a [ThemeMode]: `system` (the default) follows the device
/// appearance; `light`/`dark` are explicit user choices. The single [instance]
/// sits above `MaterialApp`, which rebuilds when it changes (see `main.dart`).
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'app_theme_mode';

  /// Restore the saved choice. Call once before `runApp`.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_prefsKey)) {
      case 'light':
        value = ThemeMode.light;
      case 'dark':
        value = ThemeMode.dark;
      default:
        value = ThemeMode.system;
    }
  }

  /// Set and persist the theme mode.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.system) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, mode == ThemeMode.dark ? 'dark' : 'light');
    }
  }
}
