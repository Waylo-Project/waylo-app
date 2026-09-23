# Settings — information spec (for design handoff)

Status: **planning only, not built.** This file fixes *what goes where* so the
design pass (handled separately) has a concrete inventory. No layout/visual
decisions here — those are the designer's. No code yet.

Scope reminder (CLAUDE.md): waylo is a minimal map-photo app. The photo
visibility model is currently "friends only", enforced by RLS — making it
user-configurable is a security-sensitive change (see open decision). Per-user
map customization is a core IN feature. Push notifications, payments, chat, feed,
comments/likes are OUT.

## Locked decisions
- **One Settings screen, grouped into sections** (not a separate "Settings" vs
  "Account" destination). waylo is small — one obvious place, setlog-minimal.
- **Map style stays where it is now** (the "You" menu item, currently "coming
  soon"). It is NOT moved into Settings.
- **Gender / birth date are hidden** in Settings (collected at sign-up only).
- **Account deletion is included** from the start.
- **Sign out stays in the "You" menu** (its current location) — NOT in Settings.
- **No bio field.**

## Entry point
- Add a **Settings** item to the existing "You" menu (top-right on the map),
  opening this screen as a pushed page.
- The "You" menu keeps **Map style** and **Sign out** as today (unchanged).

## Screen structure (sections, top → bottom)

### 1. Profile (how others see you)
- **Profile photo (avatar)** — change / remove. (`avatar_path`, public
  `avatars` bucket.)
- **Username** `@handle` — editable; must stay unique (existing unique check).
- **Display name** — editable, optional. (`display_name`.)

### 2. Account (login credentials & lifecycle)
- **Email** — view, and change.
- **Password** — change.
- *(Gender / birth date: intentionally NOT shown here.)*

### 3. Preferences
- **Language** — app language picker. **This is the next thing we build after
  the settings design.** (UI is English-only today, so this needs i18n /
  localization wiring — see backend notes.) Open: which languages to offer.
- **Photo visibility** — see the open decision below. Today the model is
  "friends only", fixed and enforced by RLS. Whether this becomes a real control
  (and what options it offers) is a product + security decision, not settled.

### 4. About / info
- **App version.**
- **Terms of Service** / **Privacy Policy** links.

### 5. Bottom (account actions)
- **Delete account** — destructive; confirmation dialog; clearly separated /
  styled as dangerous. (Sign out is NOT here — it lives in the "You" menu.)

## Explicitly excluded (scope OUT)
- Notification settings (no push), blocking/mute (no feed), payments.

## Backend notes (NOT part of the design pass — for the later build)
These don't exist yet and will need work when we implement, but the designer can
ignore them:
- Profile **edit/update** path: today `ProfileRepository` only *creates* a
  profile (`createMyProfile`). Editing username/display name/avatar needs an
  update method (+ keep the username unique check).
- **Email/password change**: Supabase Auth APIs.
- **Delete account**: needs a server-side routine (RPC / Edge Function) to remove
  the auth user and cascade the user's posts/photos/friendships — cannot be a
  client-only delete. Security-sensitive; design it with RLS in mind.
- **Language**: no i18n in the app today (strings are hardcoded English). A
  language picker needs a localization layer (e.g. Flutter `intl` / arb files)
  and a stored preference. This is the next build after the settings design.
- **Photo visibility**: changing it touches the RLS policies and the photo
  visibility model — the security-critical core (CLAUDE.md "do not touch without
  discussion"). Cannot be a client-only toggle.

## Open decisions
1. **Photo visibility — what should the setting actually do?** Today everything
   is "friends only". Options range from (a) just *display* the current rule
   (no model change), to (b) a per-user default, to (c) per-post public /
   friends / private. (b) and (c) rewrite the RLS model and need a real design.
   Pick the intent before this becomes a designed control.
2. **Language — which languages to offer** (e.g. English + Korean to start?).
