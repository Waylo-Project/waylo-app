/// App-wide configuration.
///
/// The Supabase URL and publishable (anon) key are public by design (the key is
/// meant to ship in the client; Row Level Security is what protects the data).
/// They may live in source. The service_role / secret key must NEVER be here.
class AppConfig {
  /// Supabase project URL (region: Northeast Asia / Seoul).
  static const String supabaseUrl = 'https://gyjdyhxilpqbrevxqhee.supabase.co';

  /// Supabase publishable (anon) key — Project Settings -> API Keys.
  static const String supabasePublishableKey =
      '<SUPABASE_PUBLISHABLE_KEY>';

  /// Mapbox public access token (starts with `pk.`). Public by design — it
  /// ships in the app. The secret download token (`sk.`) is NOT here; it lives
  /// in the global Gradle properties and must never be committed.
  static const String mapboxPublicToken =
      '<MAPBOX_PUBLIC_TOKEN>';
}
