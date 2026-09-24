<div align="center">
  <img src="app/icon/ic_launcher.png" alt="waylo logo" width="120"/>

  <h1>waylo</h1>
  <p><strong>Enjoy Your Trip And Write It Down</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
    <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
    <img src="https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white"/>
    <img src="https://img.shields.io/badge/PostgreSQL%20%2B%20PostGIS-316192?style=for-the-badge&logo=postgresql&logoColor=white"/>
    <img src="https://img.shields.io/badge/Mapbox-000000?style=for-the-badge&logo=mapbox&logoColor=white"/>
    <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
  </p>
</div>

---

## About

waylo is a minimal, map-based photo-sharing app. Pin your photos to the places
they were taken on your own map, add friends, and open a friend's map to see
theirs. A "Recent" map shows what your friends posted in the last 24 hours.
Nothing is public: a photo is visible only to its owner and their accepted
friends.

---

## Features

### My map
<div align="center">
  <img src="docs/screenshots/01-globe.jpg" width="250"/>
  <img src="docs/screenshots/02-map.jpg" width="250"/>
</div>

- Zoomed out, a globe with a flag for every country you've posted in; tap a flag
  to fly to those photos
- Zoomed in, photos pinned where they were taken; nearby photos group into one
  pin with a count
- Every user has their own map; friends can open yours, strangers see nothing

<br/>

### Photos
<div align="center">
  <img src="docs/screenshots/03-photo-sheet.jpg" width="250"/>
  <img src="docs/screenshots/04-photo.jpg" width="250"/>
</div>

- Tap a pin to open the photo sheet: place, date, caption
- Likes and guestbook-style comments with replies
- Edit (location, date, place name, caption) or delete your own posts

<br/>

### Friends & Recent
<div align="center">
  <img src="docs/screenshots/05-recent.jpg" width="250"/>
</div>

- **Recent:** every friend's last-24-hour posts on one globe, plus a "Just in"
  card strip
- Friends list with a "passport strip" of the countries each friend has posted
  in; tap to open their map
- Search people by username, send and accept friend requests
- Push notifications (Android) for friend requests, accepts, likes and comments

<br/>

### Posting
<div align="center">
  <img src="docs/screenshots/06-post.jpg" width="250"/>
</div>

- Pick from your library or take a photo, then crop (preset or free ratio)
- Location and date are read from the photo; fine-tune by dragging the map,
  searching a place, or typing coordinates
- The place name is filled in automatically and can be edited

<br/>

### Everywhere
- Five languages (English, 한국어, 日本語, 中文, Español), including place names
  and push notifications
- Light and dark themes

---

## How It Works

There is no custom server. The app talks to Supabase directly, and every access
rule lives in the database.

```mermaid
flowchart LR
    app["Flutter app"]
    subgraph supabase["Supabase"]
        auth["Auth"]
        db[("Postgres + PostGIS<br/>RLS on every table")]
        storage["Storage<br/>photos (private) · avatars"]
        fn["Edge Function<br/>send_push"]
    end
    mapbox["Mapbox<br/>globe map · geocoding"]
    fcm["Firebase Cloud Messaging"]

    app -- "sign in" --> auth
    app -- "queries · RPC" --> db
    app -- "upload · signed URLs" --> storage
    app -- "tiles · place names" --> mapbox
    db -- "webhooks: like, comment,<br/>friend request" --> fn
    fn --> fcm --> app
```

- **Access control is Row Level Security, not app code.** Whether you can see a
  photo (owner or accepted friend) is decided by Postgres policies, and the
  actor always comes from `auth.uid()`, never from the request.
- **Multi-row writes are single Postgres functions** (create a post, accept a
  friend request, delete an account), so they can't half-fail.
- **Map queries use PostGIS:** each user's map asks for their posts inside the
  visible bounding box, plus per-country aggregates for the flag view.
- **Fast markers:** a small thumbnail is uploaded next to every photo, markers
  are clustered on screen and cached on disk, so the map fills in quickly even
  though the photo bucket is private.

---

## Database ERD

```mermaid
erDiagram
    profiles ||--o{ posts : "posts"
    posts ||--|{ post_photos : "has"
    profiles ||--o{ friend_requests : "sends / receives"
    profiles ||--o{ friendships : "has"
    posts ||--o{ post_likes : "receives"
    profiles ||--o{ post_likes : "gives"
    posts ||--o{ post_comments : "has"
    profiles ||--o{ post_comments : "writes"
    post_comments ||--o{ post_comments : "replies"
    profiles ||--o{ device_tokens : "registers"

    profiles {
        uuid id PK "auth user id"
        text username
        text display_name
        text avatar_path
        text gender
        date birth_date
    }
    posts {
        uuid id PK
        uuid user_id FK
        geography location "PostGIS point"
        text caption
        timestamptz taken_at
        text country_code
        text place_label
    }
    post_photos {
        uuid id PK
        uuid post_id FK
        text image_path "Storage path"
        int position
    }
    friend_requests {
        uuid id PK
        uuid from_user FK
        uuid to_user FK
        text status "pending, accepted, declined"
    }
    friendships {
        uuid user_id PK, FK
        uuid friend_id PK, FK
    }
    post_likes {
        uuid post_id PK, FK
        uuid user_id PK, FK
    }
    post_comments {
        uuid id PK
        uuid post_id FK
        uuid user_id FK
        uuid parent_id FK "reply to"
        text body
    }
    device_tokens {
        text token PK
        uuid user_id FK
        text platform
        text language
    }
```

---

## Tech Stack

| | Technology |
|---|---|
| **App** | Flutter (Dart) · Android first, iOS pending |
| **Map** | Mapbox Maps SDK (globe projection) · Mapbox Geocoding |
| **Backend** | Supabase: Postgres + PostGIS, Auth, Storage |
| **Access control** | Row Level Security + Postgres functions (RPC) |
| **Push** | Supabase Edge Function (TypeScript) → Firebase Cloud Messaging |
| **i18n** | Flutter gen-l10n, 5 languages |

---

## Getting Started

Keys are not in the repo. You need:

- the Flutter SDK;
- a Mapbox **secret download token** (`sk...`, scope `DOWNLOADS:READ`) in
  `~/.gradle/gradle.properties`: `MAPBOX_DOWNLOADS_TOKEN=sk...`;
- `app/lib/config/app_keys.dart`, copied from `app_keys.example.dart` and
  filled in (Supabase publishable key, Mapbox public `pk.` token);
- `app/android/app/google-services.json` from the Firebase console.

Then, with an Android device attached:

```bash
cd app
flutter pub get
flutter run
```

Checks: `flutter analyze` and `flutter test` (from `app/`).

See `CLAUDE.md` → "Setting up on a new machine" for where each key comes from,
and "Applying schema changes" before adding a migration. Server-side secrets
(`service_role`, the FCM service account, the webhook secret) live only in the
Supabase dashboard.

### Repository

```
app/        Flutter app (lib/, android/, ios/, test/)
supabase/   migrations/ (schema, RLS, RPCs, storage) · functions/send_push/
docs/       ROADMAP.md (status + plan), DESIGN.md, POST.md, SETTINGS.md
CLAUDE.md   scope, architecture rules, code map, setup
```

---

## Developer

**Jihun Cho**
- GitHub: [@Jihun37](https://github.com/Jihun37)
