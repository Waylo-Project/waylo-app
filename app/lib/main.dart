import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'core/locale_controller.dart';
import 'core/push_messaging.dart';
import 'core/theme_controller.dart';
import 'features/auth/auth_gate.dart';
import 'features/map/map_home_page.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MapboxOptions.setAccessToken(AppConfig.mapboxPublicToken);

  // Firebase (Android push). Best-effort: a failure (e.g. iOS without APNs)
  // must never block app start.
  try {
    await Firebase.initializeApp();
    // Draw background / terminated pushes ourselves (data-only messages), so
    // the notification can carry the real app icon. See push_messaging.dart.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[push] Firebase init failed: $e');
  }

  // Restore the saved language + theme choices before the first frame.
  await LocaleController.instance.load();
  await ThemeController.instance.load();

  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );

    // Register this device for push when signed in (now, and on later sign-ins).
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) PushMessaging.instance.register();
    auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        PushMessaging.instance.register();
      }
    });
  }

  runApp(const WayloApp());
}

class WayloApp extends StatelessWidget {
  const WayloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.instance,
        builder: (context, locale, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          // `system` follows the device appearance; light/dark are explicit.
          themeMode: themeMode,
          // `locale` null follows the device language; a non-null value is the
          // user's explicit choice. Unsupported locales fall back to English.
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // If Supabase isn't configured, skip auth and show the map with a banner.
          home: AppConfig.isSupabaseConfigured
              ? const AuthGate()
              : const MapHomePage(),
        ),
      ),
    );
  }
}
