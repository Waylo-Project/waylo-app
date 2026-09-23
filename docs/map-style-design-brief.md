# Design brief — waylo personal map customization ("my own map")

> Hand-off to **claude design**. This doc is self-contained: it assumes no prior
> knowledge of the waylo codebase. Deliverables requested are at the bottom.

## 1. Product context (read first)
**waylo** is a minimal, map-based photo-sharing app. You pin your photos to
locations on a map, add friends, and see a friend's photos on *their* map. The
map is the home screen. Design north star: the clean, single-purpose feel of
**setlog** — no clutter, **one job per screen**.

Brand: a **sky-blue squiggle** mark (no wordmark). The app uses a **single
sky-blue accent** (`AppColors.primary`); design must **not** introduce a second
accent color. Platform: **Flutter, phone screens** (iOS + Android), Mapbox map
with **globe projection always on**.

## 2. The feature being designed
**Personal map customization** — a *core identity feature* ("my own map"). Each
user styles **their own base map** (theme / colors); the choice is saved to their
profile and applied to *their* map at runtime.

Key semantic: **a style belongs to the map's owner.** When you view a friend's
map, you see **the friend's** chosen style — each person's map looks the way
*they* made it. (The photo-visibility rules are unchanged and not part of this
brief.)

Entry point already exists in the app: the top-right **"You"** menu has a
**"Map style"** item (currently a "Coming soon" stub). That's where the picker
opens from.

## 3. Chosen scope (decided with the product owner)
**Full power, including users picking colors directly** (runtime layer
recoloring), on top of preset styles and "mood" presets. So the design must cover
both *preset choice* and *free-form color customization*.

## 4. What's technically possible (design within this — it's all buildable)
The map is Mapbox via `mapbox_maps_flutter`. Capabilities, by lever:

- **A. Preset base-style swap.** Drop-in full styles: Light, Dark, Satellite,
  Streets, Outdoors, Satellite-Streets, Standard. One tap = whole new look.
- **B. "Mood" presets (Standard style config).** The Standard style exposes
  `lightPreset` = **dawn / day / dusk / night** (same map, different time-of-day
  mood) plus label on/off toggles (places, roads, POIs, transit). Cheap, high
  visual impact.
- **C. Custom brand styles (Mapbox Studio).** We can author bespoke waylo styles
  in Studio (e.g. a pastel theme, a dark-neon theme) and load them by URL. Good
  for a signature "waylo look."
- **D. Free-form color recoloring (the chosen power feature).** After a style
  loads, individual map elements can be recolored live by the user.

### ⚠️ Hard technical constraint on D — design around this
Free-form recoloring only works cleanly on a **classic base style** (Streets /
Light / Outdoors) where map layers have stable, known IDs. The **Standard** style
**hides its layers**, so arbitrary per-layer recoloring does **not** work there —
Standard only allows the B-style "mood" config.

Therefore: **do not** design "recolor anything." Design recoloring as a
**bounded, fixed set of slots** the user can tint. Proposed slot set (designer may
refine, but keep it small and meaningful):
- **Water**
- **Land / background**
- **Green / parks**
- **Roads**
- **Buildings**
- **Labels (text)**

Picture it like "pick a color for water, land, roads…" — not a Photoshop layer
panel. 6-ish slots max keeps it both usable and implementable.

## 5. Constraints the design MUST respect
1. **Marker legibility on every background.** Photos render on the map as
   **rounded-square thumbnails with a sky-blue border**, and zoomed-out the map
   shows **country flags**. These sit *on top* of the base map. Any style/colors
   the user can produce (incl. dark or satellite) must keep markers + flags
   readable — design should account for contrast (e.g. marker treatment that
   survives a dark or busy background).
2. **Globe projection stays on** at all zooms (zoomed out = a real sphere).
   Style/look concepts should look good on the globe, not just a flat map.
3. **setlog-minimal.** The picker is one focused surface, not a settings maze.
4. **Single accent.** Sky-blue is the only brand accent in *chrome/UI*; the
   *map itself* is what gets recolored (that's the point), but the surrounding UI
   controls stay on-brand and restrained.
5. **Phone-first**, thumb-reachable controls.

## 6. Deliverables requested (BOTH)
**(a) Style-selection / customization UI**
- Where & how the user picks a preset and then customizes colors.
- Opens from the "You" → "Map style" entry.
- Should cover: choosing a **preset** (A/B/C) with **live preview**; a
  **mood** control (dawn/day/dusk/night) where applicable; a **color-customize**
  surface for the bounded slots in §4-D; **apply / save**; **reset to default**.
- Minimal, one-job feel. Show the states (browsing presets vs. fine-tuning colors).

**(b) Map "look" concepts (reference targets)**
- 2–4 concrete map looks as palette + mood targets — e.g. a **default waylo
  light**, a **night/dark**, a **pastel**, a **satellite** look.
- For each, show how a **photo marker** and a **country flag** sit on it (so we
  can verify legibility, per §5-1).

## 7. Out of scope (do not design)
- 3D terrain / buildings extrusion, custom map fonts, animation-heavy transitions.
- Anything beyond the base-map look + the picker (no profile canvas, no widgets —
  those are cut from the product).

## 8. Open questions for the designer to propose on
- Final slot set for color customization (start from §4-D's six).
- Whether color customization is **per-preset** (tint on top of a chosen base) or
  a standalone "build your own" mode — recommend the simpler model.
- Preview mechanism: live on the real map vs. static swatch cards.
