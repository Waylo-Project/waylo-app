# waylo

A minimal, map-based photo-sharing app. Pin your photos to places on your own
map, add friends, and open a friend's map to see theirs. A "Recent" map shows
what friends posted in the last 24 hours. Photos are visible only to you and
your accepted friends.

- **App:** Flutter (Android first; iOS pending), Mapbox maps with a globe view.
- **Backend:** Supabase: Postgres + PostGIS, Auth, Storage, and row-level
  security for every access rule. There is no custom server; multi-row logic
  lives in SQL functions, and push notifications go through one Edge Function.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/01-globe.jpg" width="240" alt="Globe view with country flags"><br><sub>Your map, zoomed out: a flag per country</sub></td>
    <td align="center"><img src="docs/screenshots/02-map.jpg" width="240" alt="City view with photo markers"><br><sub>Zoomed in: photos pinned where they were taken</sub></td>
    <td align="center"><img src="docs/screenshots/03-photo-sheet.jpg" width="240" alt="Photo sheet over the map"><br><sub>Tap a photo: place, date, likes, comments</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/04-photo.jpg" width="240" alt="Expanded photo sheet"><br><sub>The photo sheet, expanded</sub></td>
    <td align="center"><img src="docs/screenshots/05-recent.jpg" width="240" alt="Recent map of friends' posts"><br><sub>Recent: friends' last 24 hours on one map</sub></td>
    <td align="center"><img src="docs/screenshots/06-post.jpg" width="240" alt="Post details screen"><br><sub>Posting: location from the photo, editable place name</sub></td>
  </tr>
</table>

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
