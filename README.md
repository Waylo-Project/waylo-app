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

You need the Flutter SDK and a Mapbox **secret download token** (`sk...`,
scope `DOWNLOADS:READ`) in `~/.gradle/gradle.properties`:

```
MAPBOX_DOWNLOADS_TOKEN=sk...
```

Then, with an Android device attached:

```
cd app
flutter run
```

The public keys (Supabase publishable key, Mapbox `pk.` token) are committed on
purpose; secrets (`service_role`, the Mapbox `sk.` token, the FCM service
account, the webhook secret) never are. See `CLAUDE.md` → "Setting up on a new
machine" for the full checklist, and "Applying schema changes" before adding a
migration.
