# waylo

A minimal, map-based photo-sharing app. Pin your photos to places on your own
map, add friends, and open a friend's map to see theirs. A "Recent" map shows
what friends posted in the last 24 hours. Photos are visible only to you and
your accepted friends.

- **App:** Flutter (Android first; iOS pending), Mapbox maps with a globe view.
- **Backend:** Supabase: Postgres + PostGIS, Auth, Storage, and row-level
  security for every access rule. There is no custom server; multi-row logic
  lives in SQL functions, and push notifications go through one Edge Function.

## Repository

```
app/        Flutter app (lib/, android/, ios/, test/)
supabase/   migrations/ (schema, RLS, RPCs, storage) · functions/send_push/
docs/       ROADMAP.md (status + plan), DESIGN.md, POST.md, SETTINGS.md
CLAUDE.md   scope, architecture rules, code map, setup — start here
```

## Running it

Keys are not in the repo. You need:

- the Flutter SDK;
- a Mapbox **secret download token** (`sk...`, scope `DOWNLOADS:READ`) in
  `~/.gradle/gradle.properties`: `MAPBOX_DOWNLOADS_TOKEN=sk...`;
- `app/lib/config/app_keys.dart`, copied from `app_keys.example.dart` and
  filled in (Supabase publishable key, Mapbox public `pk.` token);
- `app/android/app/google-services.json` from the Firebase console.

Then, with an Android device attached:

```
cd app
flutter run
```

See `CLAUDE.md` → "Setting up on a new machine" for where each key comes
from, and "Applying schema changes" before adding a migration. Server-side
secrets (`service_role`, the FCM service account, the webhook secret) live only
in the Supabase dashboard.
