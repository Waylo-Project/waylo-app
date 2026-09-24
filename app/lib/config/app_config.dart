import 'app_keys.dart';

/// App-wide configuration.
///
/// The client keys ship inside the app (Row Level Security is what protects the
/// data), but the repo is public, so they live in the gitignored
/// `app_keys.dart` rather than in source. The service_role / secret key must
/// NEVER be in the app at all.
class AppConfig {
  /// Supabase project URL (region: Northeast Asia / Seoul).
  static const String supabaseUrl = 'https://gyjdyhxilpqbrevxqhee.supabase.co';

  /// Supabase publishable (anon) key.
  static const String supabasePublishableKey = AppKeys.supabasePublishableKey;

  /// Mapbox public access token (`pk.`). The secret download token (`sk.`) is
  /// NOT in the app; it lives in the global Gradle properties.
  static const String mapboxPublicToken = AppKeys.mapboxPublicToken;
}
