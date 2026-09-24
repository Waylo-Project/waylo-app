# waylo — CLAUDE.md

## What this project is
waylo is a **minimal, map-based photo-sharing app**. You pin your photos to
locations on a map, add friends, and see your friends' photos on the same map.
That is the entire product. The design north star is the clean, single-purpose
feel of **setlog**: no feature clutter, one obvious thing to do per screen.

This is a **fresh commercial rebuild**. An older, much larger version existed
(`../waylo_api`, `../waylo_flutter`) with profile canvas, widgets, chat, feeds,
comments, likes. **None of it is reused.** We deliberately cut everything down
to the four features below.

## Scope — read this before building anything
**IN scope (the whole app):**
1. **Auth** — sign up / sign in.
2. **Post a photo** pinned to a map location.
3. **Friends** — send / accept friend requests.
4. **View a friend's photos on the friend's own map** (opened from the Friends
   list / their profile). **Each user has their own map showing only their own
   photos** — photos are NOT merged onto a single shared map. (The old waylo had
   `my_map_content` for your map and `user_map_content` for a specific user's
   map; same model here. Per-user maps stay the core model; a **time-limited
   "Recent" feed** (every friend's last-24h posts on one map, see #6) is an
   accepted addition, but it does NOT replace the always-on per-user maps.)
5. **Personal map customization** — each user styles their own base map
   (theme / colors), saved to their profile. A **core identity feature** of
   waylo ("my own map"): each user's base map looks the way they made it, while
   the photo-visibility rules below stay unchanged. Drives the Mapbox provider
   choice (Google Maps cannot do free-form per-user styling).
6. **Social layer + notifications** *(adopted 2026-06-29 by product decision —
   was originally OUT)*. Photos carry **likes and comments** (guestbook-style),
   visible exactly when the photo is (owner + accepted friends). A **"Recent"
   feed** shows every friend's last-24h posts on one map. **Push notifications**
   (Android/FCM first; iOS deferred) fire for: friend request received, friend
   request accepted, and a like/comment on your photo.

**OUT of scope** (intentionally removed; do NOT build without an explicit
product decision from the user):
- Profile canvas / widgets / album decoration
- Chat / DM
- Public feed / explore / discovery (the friends-only "Recent" feed in #6 is the
  only feed — there is no public / stranger discovery)
- In-app purchases / monetization, and anything else not in the IN list.

**Rule:** if a feature is not in the IN list, it is OUT. Adding scope is a
**product decision, not a coding decision** — stop and ask the user first.

## Stack (locked decisions)
- **Frontend:** Flutter (iOS + Android), `mapbox_maps_flutter` for the map.
- **Backend:** Supabase — Postgres (+PostGIS), Auth, Storage, Row Level Security.
- **Map provider:** Mapbox. Chosen over Google Maps for two reasons that Google
  cannot do: a **globe projection**, and **per-user map customization** (styles
  are Mapbox Style-Spec JSON we can recolor / swap at runtime). Mapbox bills by
  monthly active users (free under ~25k MAU). The old waylo also used Mapbox, so
  there is prior art in `../waylo_flutter`.
- **No custom application server.** The Flutter app talks to Supabase directly.
  Complex/multi-row logic lives in **Postgres functions (RPC) or triggers**, not
  in a middle tier.

## Architecture rules (decisions Claude cannot infer from code)
- **Access control is RLS, not client code.** Every table has RLS enabled. The
  client never decides who may see what — the database does. A query that
  "works" only because the client filtered the rows is a **bug**, not a feature.
- **Identity comes from `auth.uid()`**, never from a client-supplied user id.
  Functions and policies derive the actor from the session, not the request body.
- **Multi-row logic goes in a Postgres function/trigger**, never as several
  unguarded client writes that can half-fail (e.g. accept-friend-request must
  create the friendship atomically in one RPC).
- **Photos live in Supabase Storage; tables store the storage path**, never the
  image bytes. **Map markers use a pre-generated thumbnail** uploaded next to the
  original (`*_thumb.jpg`, derived by path convention — no separate column),
  because the bucket is private and an on-the-fly Storage transform round-trips
  ~0.6–1s. Storage transform is the fallback only. (See ROADMAP "Marker
  implementation notes".)
- **Migrations are the source of truth for schema.** Every schema change is a new
  SQL file under `supabase/migrations/`. No ad-hoc edits in the dashboard that
  aren't captured as a migration.
- **Secrets never get committed.** The `service_role` key must **never** be in
  the app or the repo. The client keys (Supabase publishable key, Mapbox `pk.`
  token, `google-services.json`) do ship inside the app, but the repo is
  **public**, so they live in gitignored local files, not in source.

## Photo visibility model (core rule)
A photo is visible to: **its owner** and **the owner's accepted friends**. Nothing
is public. This single rule drives the `photos` SELECT policy and the per-user map
queries (`posts_in_view` / `flags_for_user` take a target user id and run
SECURITY INVOKER, so RLS returns a friend's posts on the friend's map and nothing
for a non-friend). If a screen shows a stranger's photo, that's a bug.

## Design principles
- **Minimal and clean** (setlog-inspired). The map is the home screen. No nested
  menus, no clutter, no out-of-scope features peeking through the UI.
- Every screen must justify itself against the four in-scope features. If it
  doesn't serve one of them, it doesn't ship.

## Layout
```
waylo2/
  app/         Flutter app
  supabase/    migrations/  (schema, RLS, RPCs, storage — all applied to the shared project)
               functions/send_push/  (Edge Function: FCM pushes, called by DB webhooks)
  docs/        ROADMAP.md (status + plan), DESIGN.md (UI + marker model),
               POST.md, SETTINGS.md (feature specs)
  CLAUDE.md    this file
```

Code map (`app/lib/`):
- `config/app_config.dart` — Supabase + Mapbox public keys.
- `core/` — app-wide pieces: `lat_lng` (provider-agnostic coordinate),
  `locale_controller` / `theme_controller` (persisted language + light/dark),
  `push_messaging` (FCM token + drawing notifications), `user_avatar`,
  `photo_library` (library loading + thumbnail grid for the pickers),
  `date_format`, `validators`, `error_dialog`.
- `data/` — repositories: `profile_`, `post_` (upload + create_post),
  `feed_` (map queries, thumbnails, post detail, likes, comments, edit/delete),
  `friends_`, `geocoding` (Mapbox reverse/forward lookups, country center).
- `features/auth/` — sequential sign-up + sign-in + `AuthGate`.
- `features/map/` — `map_home_page` (your map + chrome), `photo_map_view`
  (the reusable map: markers, clustering, flags; per-user or Recent feed),
  `friend_map_screen` (a friend's map), `photo_marker` (compose marker PNGs),
  `marker_cache` (disk cache).
- `features/post/` — library grid → crop → details (location, place name,
  date, caption); the details screen doubles as the post editor.
- `features/photo/photo_sheet.dart` — the tapped-photo sheet (carousel, likes,
  comments, edit/delete).
- `features/friends/friends_screen.dart` — Recent map / friends / requests /
  find.
- `features/settings/` — settings + avatar picker; `features/legal/` — in-app
  Terms / Privacy.
- `l10n/` — ARB files (en is the template; ko, ja, zh, es) + generated
  `AppLocalizations`. Edit the ARBs, then `flutter gen-l10n`.

Migrations apply in filename (timestamp) order; a later file may supersede an
earlier function (e.g. `per_user_map` replaced the map RPCs, `place_label`
replaced `create_post` / `update_post`).

**Push webhooks:** `send_push` rejects any request without the
`x-webhook-secret` header matching its `WEBHOOK_SECRET` secret. The three
Database Webhooks that call it (dashboard → Integrations → Database Webhooks)
send that header. The secret lives only in the dashboard, never in the repo.

## How to run
The app lives in `app/`. With a device attached:

```
cd app
flutter run -d <device-id>        # e.g. an attached Android phone
```

Checks (from `app/`): `flutter analyze` must stay clean; `flutter test` runs the
unit tests.

What's committed and ready:
- `lib/config/app_config.dart` holds the Supabase URL and reads the client keys
  from the gitignored `lib/config/app_keys.dart` (see setup below).
- The Supabase project is **shared** (same keys for everyone) and already has all
  `supabase/migrations/` applied, plus "Confirm email" OFF (the current auth flow
  has no email deep-link). So a collaborator does NOT re-set-up Supabase.
- It is on the **free plan, which pauses the project after ~7 idle days**. If the
  dashboard is greyed out / stuck on "Checking..." or the app can't reach
  Supabase, restore the project from the dashboard first (data is kept).

## Setting up on a new machine (collaborator onboarding)
These are NOT in the repo and must be provided locally:
1. **Flutter SDK** installed (the original machine had it at `C:\flutter`; yours
   may differ — just have `flutter` on PATH).
2. **Mapbox secret download token** (`sk...`, scope `DOWNLOADS:READ`) — needed to
   download the Mapbox Android SDK at build time. It must **never be committed**.
   Put it in your **global** Gradle props `~/.gradle/gradle.properties` as
   `MAPBOX_DOWNLOADS_TOKEN=sk...` — NOT in `app/android/gradle.properties`,
   which is tracked. `app/android/build.gradle.kts` reads it as a Gradle
   property for the Mapbox maven repo. Get the token from the shared Mapbox
   account (`jihunn`) → account.mapbox.com → Create a token → check
   `DOWNLOADS:READ`.
3. **Client keys:** copy `app/lib/config/app_keys.example.dart` to
   `app_keys.dart` (same folder) and fill in the Supabase publishable key
   (Supabase dashboard → Project Settings → API Keys) and the Mapbox public
   `pk.` token (account.mapbox.com → Tokens). Without it the app won't compile.
4. **`app/android/app/google-services.json`** (Firebase, for push): download it
   from the Firebase console (project `waylo-fba9d` → Project settings → the
   Android app `com.waylo.waylo`). Without it the Android build fails.

**Applying schema changes:** migrations are applied **manually in the Supabase
SQL Editor** (no CLI link yet). When you add a file under `supabase/migrations/`,
paste + Run it there. Existing files are already applied to the shared project.

**Cross-drive Windows gotcha:** if your project and the Pub cache end up on
different drives (original was project on `D:`, cache on `C:`), Kotlin's
incremental compiler crashes ("this and base files have different roots"), so
`app/android/gradle.properties` sets `kotlin.incremental=false`. Harmless on a
single drive; keep it. If a build cache corrupts, `flutter clean` then re-run.

## Working style
- **Discuss the approach before writing code** for a new direction. Prefer
  minimal, targeted changes over rewrites.
- **Do not claim something works from self-assessment.** Verify by running it
  (app builds, query returns the right rows under RLS, photo actually uploads).
- Keep code comments in **English**.

## Do not touch without discussion
- The locked stack decisions above.
- RLS policies and the photo visibility model — security-critical.
- The old `../waylo_api` and `../waylo_flutter` (legacy reference only, read-only).

## Roadmap
Staged plan and the explicitly-deferred parking lot live in
**`docs/ROADMAP.md`**. Read it when starting a new phase.
