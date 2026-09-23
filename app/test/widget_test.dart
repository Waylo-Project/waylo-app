// Smoke tests for waylo.
//
// The home screen embeds a GoogleMap platform view, which does not render in
// the widget-test environment, so we keep tests here to plain Dart logic for
// now. Feature-level tests will be added per phase.

import 'package:flutter_test/flutter_test.dart';
import 'package:waylo/config/app_config.dart';

void main() {
  test('Supabase is reported as unconfigured until the key is filled in', () {
    // The committed placeholder should read as "not configured".
    expect(
      AppConfig.isSupabaseConfigured,
      AppConfig.supabasePublishableKey != 'PASTE_SUPABASE_PUBLISHABLE_KEY_HERE',
    );
  });
}
