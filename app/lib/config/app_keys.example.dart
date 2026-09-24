// Template for app_keys.dart, which holds the app's client keys and is kept
// out of git (the repo is public). Copy this file to app_keys.dart next to it
// and fill in the values:
//   - Supabase publishable key: Supabase dashboard -> Project Settings -> API Keys
//   - Mapbox public token (pk.*): account.mapbox.com -> Tokens
abstract final class AppKeys {
  static const String supabasePublishableKey = 'sb_publishable_...';
  static const String mapboxPublicToken = 'pk.eyJ...';
}
