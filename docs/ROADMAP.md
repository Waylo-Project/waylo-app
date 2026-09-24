# waylo — ROADMAP

Staged build plan for the minimal map-based photo app. Read `../CLAUDE.md`
first for scope and rules, and `DESIGN.md` for the UI flow, visual language, and
the map-marker performance model. Each phase should be shippable/testable on its own.
Do not pull work forward from a later phase without reason — the point of the
staging is to keep each step small and verifiable.

Status legend: `[ ]` not started · `[~]` in progress · `[x]` done.

## Status at a glance (for someone picking this up)
- **Done & verified on device:** Phase 0 (foundations), 1 (auth), 2 (post a
  photo → markers: photo tier + clusters + country flags + tap/carousel sheet),
  3 (friends: search / request / accept / list / remove).
- **Done & verified (2 accounts):** Phase 4 — **per-user maps**. Your home map
  shows only your photos; a friend's photos are on the friend's map (Friends list
  → tap a friend). Owner verified a friend's photo shows on their map; non-friend
  visibility is blocked by RLS (and a non-friend's map isn't reachable in the UI).
- **Also done:** Phase 7 geocoded place-name localization; in-app ToS + Privacy
  screens (Settings → About; draft pending legal review).
- **Next up:** Phase 6 — design polish (the photo sheet / overall visual aren't
  final). Phase 5 — **personal map customization** ("my own map", the core
  identity feature; Mapbox style JSON) is **deferred by owner decision** for now,
  picked up after the polish pass.
- **Before running:** apply any not-yet-applied `supabase/migrations/` in the
  SQL Editor, and set `MAPBOX_DOWNLOADS_TOKEN` locally (see `../CLAUDE.md`
  "Setting up on a new machine"). Latest migration: `place_label`.
- **Known design debt:** the photo sheet design is a first draft the owner
  isn't happy with — intentionally deferred to Phase 6, don't polish piecemeal.

---

## Phase 0 — Foundations
Goal: an empty but correct skeleton that an authenticated user can connect to.
- [x] Create the Supabase project (ref `gyjdyhxilpqbrevxqhee`, region Seoul).
      Record project URL + `anon` key in the app config (not committed).
- [ ] `supabase/` initialized with the CLI; link to the project (for future
      migrations). First apply was done manually via the SQL Editor.
- [x] Schema migration: `profiles`, `posts`, `post_photos` (PostGIS
      `geography(Point)`), `friend_requests`, `friendships`. PostGIS enabled.
      **Applied to the project.**
- [x] RLS enabled on every table, with the photo visibility model from CLAUDE.md
      (owner + accepted friends only). **Applied.**
- [x] RPCs: `create_post`, `send_friend_request`, `respond_to_friend_request`,
      `remove_friend`. **Applied.**
- [x] Storage buckets (`photos` private, `avatars` public) with access policies
      matching the visibility model. **Applied.**
- [x] Flutter app scaffolded in `app/` (android, ios); `supabase_flutter` +
      `google_maps_flutter` added; map home screen + Supabase init wired.
      `flutter analyze` clean.
- [x] Fill in the keys: Supabase publishable key (`AppConfig`) and the Google
      Maps **Android** key (AndroidManifest). iOS key deferred (needs a Mac).
- [x] App connects to Supabase and renders the map on the device (Galaxy S20+,
      Android 13). CLAUDE.md "How to run" filled in.
      Note: `kotlin.incremental=false` required (project on D:, Pub cache on C:).

## Phase 1 — Auth  ✅ DONE (verified on device)
Goal: a user can create an account and stay signed in.
- [x] Email + password sign in / sign up. (Google + Apple still deferred to
      before store launch.)
- [x] Sequential sign-up flow, ported from the original app (sky-blue theme,
      "Create account" steps), in this order:
      **email → password → birth date → gender → username**. The account
      (auth user + `profiles` row) is created in one shot at the username step.
      Original copy + validation rules reused (email regex; password 10+ with
      letters & numbers; username 1-30 with the original regex).
- [x] `profiles` row created with username, gender, birth_date. (Display name
      column exists but isn't collected; profile photo intentionally not asked
      at sign-up.)
- [x] Session persistence + sign-out (profile sheet on the map). App gated
      behind `AuthGate`. Stale/deleted session self-recovers (FK 23503 / null
      profile -> sign out -> Welcome).

Notes for whoever picks this up next:
- Login is verified working on the Galaxy S20+ (Android 13).
- Requires Supabase **"Confirm email" OFF** for the current flow (no email
  deep-link handling yet) and the `profile_fields` migration applied.
- Auth screens live in `app/lib/features/auth/`; theme/colors in
  `app/lib/theme/app_theme.dart`.

## Phase 2.0 — Map provider migration: Google Maps → Mapbox  ✅ DONE (verified on device)
Decision (see `../CLAUDE.md` and `DESIGN.md`): the map moves to **Mapbox** for a
globe projection and per-user map customization. Done before the rest of
Phase 2's map work so markers/clustering are built once, on Mapbox.
- [x] Added `mapbox_maps_flutter` (2.25.0); removed `google_maps_flutter`. Tokens
      wired: public token in `AppConfig` (`MapboxOptions.setAccessToken` in main),
      `MAPBOX_DOWNLOADS_TOKEN` in the global `~/.gradle/gradle.properties` (never
      committed) + Mapbox maven repo in `android/build.gradle.kts`.
- [x] Replaced the map home (`map_home_page`) and the confirm-location screen
      (`confirm_location_screen`) with Mapbox `MapWidget` (`CameraViewportState`);
      **globe projection on** via `style.setProjection(globe)`.
- [x] Added a neutral `LatLng` (`lib/core/lat_lng.dart`); the post flow
      (`new_post_draft`, `post_location_service`, `start_new_post`) uses it. Only
      the map widgets convert to Mapbox `Point`/`Position` at the boundary. The
      photo-pick / EXIF / location / permission logic was untouched.
- [x] Removed the Google Maps API key from AndroidManifest.
      Note: `com.mapbox.common.*` `ClassNotFoundException` lines in logcat are
      benign Mapbox init probes, not errors.

## Phase 2 — Post a photo to the map
Goal: a signed-in user can put one of their photos on the map.
See `DESIGN.md` for the post-photo flow, marker design, and performance model.
- [x] Pick/take a photo; capture its location: **photo GPS first, with a map-pin
      fine-tune**, device location as fallback. **Verified on device.**
      - Gallery picks go through `photo_manager`, which
        reads the asset's real GPS via `latlngAsync()`. `image_picker` returns a
        re-encoded copy with coordinates stripped (0/0), so it can't be used for
        gallery location — camera capture still uses `image_picker` (fresh shots
        have no GPS → device-location fallback).
      - Needs `ACCESS_MEDIA_LOCATION`, requested at runtime via
        `permission_handler`; without it the OS redacts the photo's GPS.
      - Flow code in `app/lib/features/post/` (start_new_post, confirm_location_screen,
        post_location_service, new_post_draft). The confirm step currently ends with
        a SnackBar — the upload below replaces it.
- [x] Upload to Storage + write the post atomically. **Verified on device
      ("Posted!", no errors).** Compress/resize before upload (long edge ~2048,
      JPEG q85, EXIF stripped) via `flutter_image_compress`; upload to
      `photos/{uid}/{groupId}/0.jpg`; then `create_post` RPC. Code in
      `lib/data/post_repository.dart`, called from the map FAB flow.
      (End-to-end DB proof comes when the marker renders below.)
- [x] **Photo tier (zoomed in):** photos as markers (rounded-square + sky-blue
      border). **Verified on device.** Implementation diverged from DESIGN §3 —
      see "Marker implementation notes" below.
- [x] **Flag tier (zoomed out):** one flag per country at the country center,
      below zoom 4.0 (matches old waylo's threshold). **Verified.** Flags bundled
      as assets (`assets/flags/`, 252 PNGs); per-country aggregate via `flags_all`
      RPC; country center via Mapbox forward geocode; `country_code` stored per
      post (`flags` migration + `create_post` gained `p_country_code`).
- [x] Tap a photo marker → photo sheet; tap a flag → fly into that country.
      **Verified.** Sheet = non-modal slide-up carousel (cluster shows all its
      photos), place-first "postcard" styling. **Design not final — polish in
      Phase 6.**

### Marker implementation notes (deviations from DESIGN §3 — the *what* holds, the *how* changed)
- **Not GL source clustering.** Mapbox `addStyleImage` failed (channel error) and
  GL clustering can't render a representative photo + count badge. So markers are
  **`PointAnnotationManager`** annotations with inline image bytes, and clustering
  is **done in Dart** (`_clusterByScreen`, screen-pixel grid) so a cluster can show
  a representative thumbnail with a corner count badge (Apple-Photos style).
- **Diffed, not rebuilt:** each refresh adds/removes only changed annotations
  (no flicker). Image swap = delete + recreate (annotation image isn't updatable).
  **Swap one at a time with serial `create`, NOT `createMulti`.** `createMulti`
  does not apply distinct per-annotation inline images — the photos render as grey
  placeholders. Learned the hard way; serial `create` is required for the swap.
- **Speed:** the bottleneck was the **private-bucket download round-trip (~0.6–1s)**,
  not the transform. Fixes: pre-generate a `*_thumb.jpg` at upload; **disk cache**
  composed marker PNGs (`marker_cache.dart`); **2-pass** (instant grey placeholder
  → swap in photo). DESIGN §3's "Storage transform thumbnail" is the fallback only.
- **Speed, measured (debug logs, since removed):** the ~600ms is pure **round-trip
  latency** — the same for a `download()` of a 17KB thumb, a signed-URL GET, and a
  4KB on-the-fly transform. So file size / method don't change it, and signed-URL
  is *slower* (two round-trips: sign + GET). Dead ends tried and reverted:
  **margin-expanded fetch** (pre-downloads off-screen thumbs and gates the visible
  ones on `Future.wait` → slower first paint) and **batched swap**. Parallel
  downloads + disk cache + 2-pass placeholder are already at the latency floor.
  **The only remaining lever for "instant" markers is a tiny preview carried in the
  `posts_in_view` row** (dominant color / ~16px micro-JPEG base64 / blurhash), so a
  marker paints with zero extra round-trip and the crisp thumb swaps in behind it.
  Not built — revisit if first-paint instantness matters.
- Code: `features/map/map_home_page.dart`, `photo_marker.dart`, `marker_cache.dart`,
  `data/feed_repository.dart`, `data/geocoding.dart`, `features/photo/photo_sheet.dart`.

## Phase 3 — Friends  ✅ DONE (verified on device, 2 accounts)
Goal: users can connect. Backend already existed (tables + RPCs); this was UI.
- [x] Find a user (by username) and send a friend request.
- [x] See incoming requests; accept/decline via the `respond_to_friend_request`
      RPC (atomic friendship). Friends list with remove.
- [x] Friends hub: 👥 button on the map → `FriendsScreen` (tabs Friends /
      Requests / Find). Code: `data/friends_repository.dart`,
      `features/friends/friends_screen.dart`.

## Phase 4 — Friends on the map (per-user maps, not merged)
Goal: see a friend's photos **on the friend's own map**. Correcting an earlier
wrong build (own + friends merged onto one map) — the real model (per old waylo:
`my_map_content` vs `user_map_content`) is **each user has their own map**.
- [x] Map view extracted to `PhotoMapView(userId, showComposeFab)`. Home =
      your map (FAB on); a friend's map opens from the Friends list (tap a
      friend → `FriendMapScreen`, no FAB). Queries scoped by target user id
      (`posts_in_view(..., p_user_id)`, `flags_for_user`) — migration
      `per_user_map`. **Apply that migration before running.**
- [x] Verify a friend's photo appears on the friend's map (2 accounts).
      **Verified by the owner with multiple accounts.**
- [x] A non-friend's photos never appear (RLS: a non-friend id returns nothing
      even though the client asked). Enforced server-side; a non-friend's map is
      not even reachable in the UI (you open a friend's map only from your
      friends list).
- A merged "all friends on one map" view is a separate, deferred idea (see CLAUDE.md).

## Phase 5 — Personal map customization ("my own map")
Goal: the core identity feature — each user makes their map theirs.
See `DESIGN.md` §4. Built on Mapbox Style-Spec JSON.
- [ ] Offer a small set of base map styles (theme/colors) the user can pick from.
- [ ] Persist the choice on the user's `profile`; apply it to their map at runtime.
- [ ] (Stretch) finer customization — recolor specific layers, not just preset swap.

## Phase 6 — Design polish
Goal: setlog-level clean.
- [ ] Refine the map-home, photo-detail, and friends screens to the minimal aesthetic.
- [~] Empty states, loading, error handling. Icon, splash, app name.
  - [x] **Map empty / loading / load-error states.** The friends/requests lists
        already had `_Loading` / `_Empty` / error snackbars; the gap was the map
        view, which showed a blank globe. `PhotoMapView` now asks the feed
        `hasContent()` on load and shows, over the globe: a subtle spinner while
        loading, a tailored empty hint (friend → "{username} hasn't posted";
        recent → "no photos in 24h"; your own map shows the one-time post guide
        instead), or a
        Retry overlay if the initial load throws (was a silent `debugPrint`).
        Empty state re-evaluated after post / delete. Strings: `mapEmpty*`,
        `mapLoadError` (+ existing `commonRetry`).
- [ ] Pre-store checklist (Apple sign-in present, privacy strings, permissions copy).
  - [x] **App launcher icon** (Android): the white waylo mark (`assets/logos/logo.png`)
        on the brand sky-blue (`#97DCF1`), generated at all mipmap densities via
        PIL; 1024 master kept at `app/icon/ic_launcher.png`. Legacy icon only —
        adaptive icon (foreground/background + anydpi-v26) is a later polish. iOS
        icon deferred (needs a Mac).
  - [x] In-app **Terms of Service** + **Privacy Policy** screens (Settings → About).
        Shown in-app, not an external link (no `url_launcher`, no hosted page):
        `features/legal/legal_content.dart` (bilingual draft, locale-picked) +
        `legal_screen.dart`. **Draft pending legal review** — replace the
        `support@waylo.app` placeholder and confirm the minimum age before store
        submission.

## Phase 7 — Localization (i18n)
Goal: the app speaks the user's language. Stack: Flutter's official `gen-l10n`
(ARB files under `app/lib/l10n/`, `app_en.arb` is the template / source of keys;
`flutter_localizations` + `intl`). `AppLocalizations` is generated at build time
and wired into `MaterialApp` in `main.dart`.
- [x] Infra + extract all UI strings to ARB: English, Korean, Japanese,
      Chinese (Simplified) and Spanish. Locale follows the device, English
      fallback. Dates via `DateFormat.yMMMd` (locale-ordered, with the year).
- [x] **Manual language switch**: Settings → Language offers System default +
      the five languages, applied live and persisted. `LocaleController`
      (`ValueNotifier<Locale?>` in `lib/core/`, null = follow device) sits above
      `MaterialApp` and saves to `SharedPreferences`. (Per-device, not synced via
      `profile` — that would need a migration; revisit if cross-device is wanted.)
- [x] **Localize geocoded place names**: marker/sheet country + place names come
      from Mapbox, not our ARB. `geocoding` now resolves the active UI language
      (`LocaleController.resolvedLanguageCode`: explicit choice → first shipped
      device language → English, mirroring MaterialApp) and passes Mapbox a
      `language=` param on the displayed-name calls (`reversePlaceName`,
      `reversePlaceLabel`, `searchPlaces`). Chinese is sent as `zh-Hans` (a bare
      `zh` returns Traditional names). `countryCenter` / `reverseCountryCode`
      read coords / ISO codes only, no displayed text.
- Notes: gender values and crop-ratio keys ('Original'/'Free') stay canonical
  English internally — only their display is localized. Language names are shown
  as endonyms ('English', '한국어'), not translated.

## Phase 8 — Push notifications (Android first)  ✅ built (Android)
Goal: notify a user of friend-relevant events even when the app is closed.
Adopted by product decision (was OUT). Android/FCM first; **iOS deferred** (APNs
needs an Apple Developer account + a Mac). Follows the "no middle tier" rule —
sending lives in a Supabase Edge Function triggered by DB events.
- **Events:** friend request received, friend request accepted, like/comment on
  your photo.
- [x] Firebase project + Android app (`com.waylo.waylo`); `google-services.json`
      into `app/android/app/`, Google-services Gradle plugin wired.
- [x] Flutter: `firebase_core` + `firebase_messaging`; request `POST_NOTIFICATIONS`
      (Android 13+); save the FCM token (+ app language) to `device_tokens` on
      sign-in and on a language switch; draw foreground + background pushes
      ourselves (`core/push_messaging.dart`).
- [ ] Tap-to-navigate (open the post / friend request from a notification).
- [x] Migrations `device_tokens` + `device_token_language` (RLS = own rows only).
- [x] Edge Function `send_push`: look up the recipient's tokens, call FCM HTTP
      v1, localized in en / ko / ja / zh / es. Firebase **service-account key
      stored as an Edge Function secret** — never in the app or repo (same rule
      as `service_role`).
- [x] Database webhooks `push_friend_req` (`friend_requests` insert + update),
      `push_like` (`post_likes` insert), `push_comment` (`post_comments` insert)
      → call `send_push` (never notify the actor about their own action). Each webhook sends an `x-webhook-secret` header equal to the
      `WEBHOOK_SECRET` function secret; without it `send_push` returns 401.
      (Configured in the dashboard, not a migration — the secret can't be
      committed.)

---

## Parking lot — explicitly deferred (NOT in this product)
These were in the old waylo and were cut on purpose. They are recorded here only
so they are not "rediscovered" as new ideas. Do not build any of these without a
fresh product decision:
- Chat / DM
- Profile canvas / widgets / album decoration
- Public feed / explore / discovery (the friends-only "Recent" feed is NOT this)
- In-app purchases / monetization

**Adopted out of the parking lot (2026-06-29, product decision):**
- **Likes + comments** on photos (guestbook-style) and the **"Recent" last-24h
  friends feed** — already built (`social` migration, `photo_sheet`, Recent tab).
  Now an official feature, not scope creep. See CLAUDE.md IN #6.
- **Push notifications** — see Phase 8 below.
