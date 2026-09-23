# Post a photo — information spec (for design handoff)

Status: **planning only, not built.** Fixes *what the post-a-photo flow contains*
so the design pass has a concrete inventory. No layout/visual decisions here —
those are the designer's. No code yet.

Scope reminder (CLAUDE.md): waylo is a minimal map-photo app. A photo is pinned
to a map location and visible to friends only (fixed, not a per-post setting).
One pin = one photo. No filters/stickers/feed.

## Where this lives today
Entry: the map home "(+)" menu → camera or gallery → `startNewPost` →
`ConfirmLocationScreen`. What it captures now:
- **Photo** — 1, **no crop** (uploaded as-is).
- **Location** (lat/lng) — fixed center pin over a draggable map; seeded from
  EXIF GPS → device location → map center.
- **Date** (`taken_at`) — auto from EXIF only, **no edit UI** (it is stored).
- **Caption** — optional.
- **Country code** — auto (reverse-geocoded, for the zoomed-out flag tier).

Backend: `create_post` RPC (`p_lng, p_lat, p_caption, p_taken_at,
p_image_paths, p_country_code`). Thumbnail (`*_thumb.jpg`) is pre-generated for
map markers.

## Locked decisions
- **Crop is added.** Both **preset ratios** (1:1, 4:5, …) **and free-form drag**
  (resize the crop rectangle freely).
- **One photo per pin** (unchanged; backend `post_photos` could carousel later,
  but not now).
- **Date is editable — date only** (time keeps its auto value).
- **Place name shown and editable** (e.g. "Seattle, USA").
- **Location: map drag stays the main control**, plus a search box and a
  secondary lat/lng entry (below).
- Visibility stays friends-only (no per-post control).

## Flow (steps)
1. Pick photo (camera / gallery) — as today.
2. **Crop** (NEW) — frame the photo.
3. **Details** — location (map + search + coords) · date · place name · caption.
4. Post (upload + `create_post`).

## Elements

### 1. Photo & crop (NEW)
- Crop rectangle over the photo. **Preset ratio chips** (e.g. 1:1, 4:5, 3:4,
  Original) **and free-form drag** (drag the handles/edges to any rectangle).
- Pan/zoom the photo under the crop (like the avatar cropper, but rectangular +
  resizable instead of a fixed circle).
- Result: the cropped image is what gets uploaded (the map-marker thumbnail is
  derived from it; a very tall/wide crop is center-cropped for the square pin).

### 2. Location
- **Map drag (main)** — fixed center pin; drag the map to place it. (Keep.)
- **Search box on the map (NEW)** — type a place → jump the camera there
  (forward geocoding). Pin still fine-tuned by dragging after.
- **Lat/lng entry (secondary)** — a small/advanced way to type coordinates
  directly. Not the primary control — tucked away (e.g. an expander).
- Auto-seed from EXIF GPS → device → map center stays.

### 3. Date (editable — date only)
- Auto-filled from the photo's EXIF date, with a **date picker** to change it.
  (Time keeps the auto value; not user-edited.)

### 4. Place name (show + edit)
- Auto reverse-geocoded label ("place · country"), shown and **editable** by the
  user. Today only `country_code` is derived; this adds a human-readable,
  editable place label.

### 5. Caption
- Optional free text. (Keep.)

## Explicitly excluded (scope OUT)
- Multiple photos / carousel, filters / stickers / editing beyond crop, per-post
  visibility, tagging people, mood/rating, anything not above.

## Backend notes (NOT part of the design pass — for the later build)
- **Crop**: client-side; the cropped bytes are uploaded (existing compress +
  thumbnail path). No schema change.
- **Search (forward geocoding)**: add a forward lookup to `data/geocoding.dart`
  (Mapbox Geocoding API; the public `pk…` token already ships). `geocoding.dart`
  currently only does reverse (country/place) + country center.
- **Place name**: needs a `place_label` (or similar) column on `posts` + a new
  `create_post` param + migration under `supabase/migrations/`. Today only
  `country_code` is stored.
- **Date / lat-lng / caption**: no schema change — `taken_at`, location, and
  caption already flow through `create_post`; this is UI only.

## Open decisions
All four design questions resolved (see Locked decisions). Ready for the design
pass.
