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
- **Secrets never get committed.** The Supabase `anon` key is public by design
  and may ship in the app; the `service_role` key must **never** be in the app
  or the repo.

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
  docs/        ROADMAP.md (status + plan), DESIGN.md (UI + marker model)
  CLAUDE.md    this file
```

Code map (`app/lib/`):
- `config/app_config.dart` — Supabase + Mapbox public keys.
- `core/lat_lng.dart` — provider-agnostic coordinate type.
- `data/` — repositories: `profile_`, `post_` (upload + create_post),
  `feed_` (map queries + thumbnails + post detail), `friends_`, `geocoding`
  (reverse country/place, country center).
- `features/auth/` — sequential sign-up + sign-in + `AuthGate`.
- `features/map/` — `map_home_page` (your map + chrome), `photo_map_view`
  (the reusable per-user map: markers, clustering, flags, sheet),
  `friend_map_screen` (a friend's map), `photo_marker` (compose marker PNGs),
  `marker_cache` (disk cache).
- `features/post/` — pick photo + EXIF/location + confirm.
- `features/photo/photo_sheet.dart` — the tapped-photo carousel sheet.
- `features/friends/friends_screen.dart` — friends / requests / find.

Migrations in order: `schema`, `rls`, `functions`, `storage`, `profile_fields`,
`posts_in_view`, `flags`, `flags_all`, `per_user_map` (latest supersedes the
flag/posts RPCs with per-user-id versions).

## How to run
The app lives in `app/`. With a device attached:

```
cd app
flutter run -d <device-id>        # e.g. an attached Android phone
```

What's committed and ready:
- `lib/config/app_config.dart` holds the Supabase URL + publishable key **and the
  Mapbox public access token** (`pk...`). All public-by-design, fine to commit.
- The Supabase project is **shared** (same keys for everyone) and already has all
  `supabase/migrations/` applied, plus "Confirm email" OFF (the current auth flow
  has no email deep-link). So a collaborator does NOT re-set-up Supabase.

## Setting up on a new machine (collaborator onboarding)
Two things are NOT in the repo and must be provided locally:
1. **Flutter SDK** installed (the original machine had it at `C:\flutter`; yours
   may differ — just have `flutter` on PATH).
2. **Mapbox secret download token** (`sk...`, scope `DOWNLOADS:READ`) — needed to
   download the Mapbox Android SDK at build time. It must **never be committed**.
   Put it in your **global** Gradle props `~/.gradle/gradle.properties` (or a
   gitignored `app/android/gradle.properties`) as:
   `MAPBOX_DOWNLOADS_TOKEN=sk...`
   `app/android/build.gradle.kts` reads it as a Gradle property for the Mapbox
   maven repo. Get the token from the shared Mapbox account (`jihunn`) →
   account.mapbox.com → Create a token → check `DOWNLOADS:READ`. The public
   `pk...` token in `AppConfig` is already there.

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
