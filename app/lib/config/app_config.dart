/// App-wide configuration.
///
/// The Supabase URL and publishable (anon) key are public by design (the key is
/// meant to ship in the client; Row Level Security is what protects the data).
/// They may live in source. The service_role / secret key must NEVER be here.
class AppConfig {
  /// Supabase project URL (region: Northeast Asia / Seoul).
  static const String supabaseUrl = 'https://gyjdyhxilpqbrevxqhee.supabase.co';

  /// Supabase publishable (anon) key. Paste the value from
  /// Project Settings -> API Keys -> "Publishable key" (a.k.a. anon public).
  static const String supabasePublishableKey = '<SUPABASE_PUBLISHABLE_KEY>';

  /// True once the publishable key has been filled in.
  static bool get isSupabaseConfigured =>
      supabasePublishableKey != 'PASTE_SUPABASE_PUBLISHABLE_KEY_HERE';

  /// Mapbox public access token (starts with `pk.`). Public by design — it
  /// ships in the app. The secret download token (`sk.`) is NOT here; it lives
  /// in the global Gradle properties and must never be committed.
  static const String mapboxPublicToken =
      '<MAPBOX_PUBLIC_TOKEN>';
}
