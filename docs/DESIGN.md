# waylo — DESIGN & MARKER ARCHITECTURE

UI flow, visual language, and the map-marker performance model. Read
`../CLAUDE.md` for scope/rules and `ROADMAP.md` for the staged plan. This file
is the agreed framework to build against — settle changes here before coding.

---

## 1. UI flow
The map is the home screen; everything else is a sheet or a screen reached from
it. One screen = one job (setlog-style).

```
AuthGate -> [ Map Home = YOUR map ]   <-- center of every flow

  Full-bleed map. No app bar, no tab bar -- floating chrome only:
    top-left    waylo mark (brand)
    top-right   + (post a photo)   .   avatar (You)
    bottom      ( Map | Friends )  compact 2-segment pill, NOT a full tab bar

  + (top-right)     -> Post-photo flow (pick photo -> confirm location -> post)
  Marker tap        -> Photo sheet (carousel for clusters)
  Avatar (You)      -> You sheet (profile . map style . sign out)
  Friends (pill)    -> Friends screen (find / requests / list)
                         `-- tap a friend -> THAT friend's map
```

**Per-user maps (core model):** the home map shows **only your own photos**. A
friend's photos are seen on the **friend's own map**, opened from the Friends
list. Maps are never merged. (Same `PhotoMapView(userId)` widget renders any
user's map; queries are scoped by user id, RLS-guarded.)

Prefer bottom sheets over stacked full screens so the map stays the anchor and
the app stays uncluttered.

## 2. Visual language
- **Theme:** sky-blue primary (inherited from the existing sign-up flow;
  `app/lib/theme/app_theme.dart`). Do not introduce a second accent color.
- **Brand mark:** the waylo mark is the sky-blue hand-drawn "way" squiggle at
  `assets/logos/logo3.png` (white variant `logo.png`, outline-only `logo2.png`).
  It sits small at the map's top-left, on a white rounded badge (the pale mark is
  invisible directly on the map). The mark *is* the brand -- no wordmark.
- **Map & chrome (setlog-derived):** the map is full-bleed -- no app bar, no full
  tab bar. Floating chrome only: mark top-left; + (post) and avatar (You) as round
  white buttons top-right (the existing profile button is the style template); a
  compact two-segment pill `Map | Friends` centered at the bottom -- deliberately a
  2-item pill, not a full-width tab bar (the look the owner picked from setlog).
  All UI text is in English.
- **Markers:** see §3. Two tiers — **country flags when zoomed out**, individual
  **photos when zoomed in** (rounded-square, sky-blue border; the original waylo
  design). Dense photos cluster into count bubbles; flags are never replaced.

## 3. Marker architecture (performance-critical)

> **Implementation diverged from this section — read `ROADMAP.md` "Marker
> implementation notes".** The *what* below holds (two tiers, distance
> clustering, postcard sheet). The *how* changed: markers are **Mapbox
> `PointAnnotation`s with clustering done in Dart** (GL `addStyleImage` failed
> and GL clusters can't show a representative photo + badge); thumbnails are
> **pre-generated at upload + disk-cached + 2-pass placeholder** (the private
> bucket round-trip, not the transform, was the bottleneck). The GL-source /
> Storage-transform description below is the original plan, kept for rationale.

### Why the old app got slow (root cause, not the marker shape)
The old design itself was fine. Slowness came from the *pipeline*, where four
costs were multiplied together and bound to the zoom event:
1. **Loaded every photo** for the map regardless of viewport.
2. **Downloaded thumbnails sequentially**, one network round-trip per marker.
3. **Re-composited every marker bitmap** (Canvas border) on every refresh, on
   the main isolate.
4. **Delete-all + recreate-all** on each update; no diffing. Zoom was polled by
   a periodic timer that triggered a full visibility rebuild.

The new model breaks all four. The marker *visual* is unchanged.

### Two display tiers, switched by zoom (this is the model — read it)
waylo shows the map at two levels, exactly like the old waylo. **Country flags
are the zoomed-out tier and stay.** Clustering is a *photo-tier* concern, not a
replacement for flags.

**Tier A — country flags (zoomed out).**
- Below a zoom threshold, show **one flag per country** that has any visible
  photo, placed at that country's location. This is the "where in the world"
  overview — the signature waylo look.
- Tapping a flag flies the camera into that country.
- Needs a country per post: reverse-geocode the post location at post time and
  store a `country_code` on the post, so flags aggregate by country. (Data-model
  implication — not yet built; added when the flag tier is built.)

**Tier B — photos (zoomed in).**
- Above the threshold, show **individual photo markers** — the original waylo
  design (rounded-square thumbnail + sky-blue border).
- **When photos are dense / overlap at the current zoom, they merge into a
  cluster** that splits apart as you keep zooming in (distance-based, Apple-Photos
  style). **A cluster renders as a representative photo thumbnail with a small
  count badge in the corner** (NOT a plain numeric bubble — that was a wrong first
  cut). Tapping a cluster opens all its photos in the sheet carousel (coincident
  photos that never separate are still all viewable). It is NOT the zoomed-out
  view; flags are.

| Zoom | Shown | Cost |
| --- | --- | --- |
| Out (below threshold) | one flag per country, at the country center | tiny — a flag per country, not per photo |
| In, photos dense | representative photo thumbnail + count badge | one composition per cluster |
| In, photos separated | original photo marker (rounded square + sky-blue border) | only the few visible; composed once, cached |

On Mapbox all three are GL layers over GeoJSON sources, switched by layer
`minzoom`/`maxzoom`: the renderer shows the flag layer below the threshold and
the clustered photo source above it, **on the GPU** — no timer, no Dart-side
zoom polling. The photo source uses `cluster: true` so the merge/split happens
in the renderer.

### Why the old app got slow was the *photo tier*, and what fixes it
The flags were never the problem; the photo markers were (see the four costs
above). The photo tier therefore obeys these pipeline rules:
- **Viewport fetch.** Query only the visible region (the `posts_in_view`
  bounding-box RPC) and update the GeoJSON source; fetch a margin slightly larger
  than the viewport so small pans/zoom-ins stay within loaded data. Zooming in
  never refetches; only panning to new area or zooming out past loaded bounds does.
- **Cluster + render is the GPU's job.** Mapbox reclusters/redraws as the camera
  moves — not our code, not the bottleneck.
- **Compose each photo image once.** Build the rounded-square+border image once,
  register it on the style (`addStyleImage`) keyed by photo id, reference it from
  the symbol layer. Count bubbles are drawn by the renderer from `point_count`.
- Thumbnails come from **Supabase Storage image transforms** (~100 px), never
  full-resolution; download **in parallel**; update **source data** (never
  tear-down-and-recreate); drive fetches from **camera-idle**.

### Performance spec — faster than old waylo (locked)
Each item kills a measured cost of the old app. All six are baseline:
1. **Flags bundled as app assets**, not downloaded from flagcdn → zero network
   for the flag tier.
2. **Flag tier fed by a server-side per-country aggregate** (`country_code`,
   count, center) → zoomed out transfers a handful of rows, not all photos.
3. **Photo tier = GL symbol layer (texture-atlas, GPU-batched) + `cluster:true`**,
   not per-marker annotations.
4. **Two-pass render:** draw cheap dots/clusters immediately on camera-idle
   (no network), then lazy-load only the on-screen thumbnails and swap them in.
5. **Disk-cache thumbnails** by photo id + size → revisits hit no network.
6. **Camera-idle fetch is debounced**, and skipped when the new bounds are
   inside the already-loaded (margin-expanded) bounds.

Deferred (not now): **blurhash** per post (a ~20-byte string in the row for an
instant zero-request placeholder) — costs a DB column + compute at upload; revisit
later if the two-pass render isn't instant enough.

## 4. Globe + per-user map customization
Two things Mapbox gives that Google could not, both core to waylo's feel:
- **Globe projection.** The map uses Mapbox's globe projection, so a zoomed-out
  view is a real sphere that flattens smoothly as you zoom in.
- **Per-user base map ("my own map").** The base map style is Mapbox Style-Spec
  JSON. Each user picks/customizes a style (theme, colors), saved to their
  profile, and it is applied to *their* map at runtime (set the style, or recolor
  layer paint properties). This changes only the base map a user sees — the
  photo-visibility rules in `../CLAUDE.md` are unchanged. This is a later phase;
  the stack is chosen now so we don't have to migrate for it.

## 5. Decisions locked here
- Map provider: **Mapbox** (`mapbox_maps_flutter`), globe projection on.
- **Navigation / chrome (locked):** map-first -- no app bar, no tab bar. waylo
  mark top-left; + (post) + avatar (You) top-right; a centered bottom 2-segment
  pill `Map | Friends`. The old waylo's 5-tab bottom bar is dropped: its tabs
  (shared map, search, chat, settings, album) are all out of scope here. Post
  moves from a FAB to the top-right +. UI text in English.
- **Brand mark (locked):** the sky-blue squiggle `assets/logos/logo3.png`; no
  wordmark.
- **Per-user maps:** each user has their own map (own photos only); a friend's
  photos are on the friend's map. Never merged. (§1)
- **Two tiers by zoom** (threshold 4.0): zoomed out = **country flags** (one per
  country, at the country center); zoomed in = **photos**.
- Zoomed-in marker: **original waylo design** (rounded-square photo + sky-blue
  border). Circular is an aesthetic-only alt with identical cost; not adopted.
- **Clustering is a photo-tier feature, not the zoomed-out view.** Dense photos
  merge into a **representative thumbnail + count badge** (Apple-Photos style),
  splitting as you zoom in (distance-based, computed in Dart). Tapping it opens
  the carousel. Flags are never replaced by clusters.
- Country flags need a **`country_code` per post** (reverse-geocoded at post
  time; stored via `create_post`).
- Post-photo location (Phase 2): **photo GPS first, with map-pin fine-tune**,
  device location as fallback.
- **Implementation specifics that overrode the original plan** live in
  ROADMAP "Marker implementation notes" (PointAnnotation, Dart clustering,
  pre-gen thumbnail, disk cache, 2-pass).
