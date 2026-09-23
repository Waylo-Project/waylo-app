-- waylo schema: profiles, posts, post_photos, friend_requests, friendships
-- Source of truth for the database schema. RLS lives in the next migration.

-- PostGIS for geography(Point) used by posts.location.
create extension if not exists postgis with schema extensions;

-- Make extension types/functions/operators resolvable in this migration.
set search_path = public, extensions;

-- ---------------------------------------------------------------------------
-- profiles: 1:1 with auth.users. Only the minimal fields the app shows.
-- ---------------------------------------------------------------------------
create table public.profiles (
    id           uuid primary key references auth.users (id) on delete cascade,
    username     text not null,
    display_name text,
    avatar_path  text,
    created_at   timestamptz not null default now()
);

-- Case-insensitive unique username (used as the friend-search key).
create unique index profiles_username_lower_idx on public.profiles (lower(username));

-- ---------------------------------------------------------------------------
-- posts: one map pin. Location and caption live here (one location per post).
-- ---------------------------------------------------------------------------
create table public.posts (
    id         uuid primary key default gen_random_uuid(),
    user_id    uuid not null references public.profiles (id) on delete cascade,
    location   extensions.geography(Point, 4326) not null,
    caption    text,
    taken_at   timestamptz,
    created_at timestamptz not null default now()
);

create index posts_user_id_idx    on public.posts (user_id);
create index posts_location_gix   on public.posts using gist (location);
create index posts_created_at_idx on public.posts (created_at desc);

-- ---------------------------------------------------------------------------
-- post_photos: the photos belonging to a post (carousel). Many per post.
-- Stores the Storage path, never the image bytes.
-- ---------------------------------------------------------------------------
create table public.post_photos (
    id         uuid primary key default gen_random_uuid(),
    post_id    uuid not null references public.posts (id) on delete cascade,
    image_path text not null,
    position   int  not null default 0,   -- carousel order: 0, 1, 2, ...
    created_at timestamptz not null default now(),
    unique (post_id, position)
);

create index post_photos_post_id_idx on public.post_photos (post_id);

-- ---------------------------------------------------------------------------
-- friend_requests: directed request, one row per (from, to) pair.
-- ---------------------------------------------------------------------------
create table public.friend_requests (
    id         uuid primary key default gen_random_uuid(),
    from_user  uuid not null references public.profiles (id) on delete cascade,
    to_user    uuid not null references public.profiles (id) on delete cascade,
    status     text not null default 'pending'
               check (status in ('pending', 'accepted', 'declined')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint friend_requests_distinct check (from_user <> to_user),
    unique (from_user, to_user)
);

create index friend_requests_to_user_idx on public.friend_requests (to_user);

-- ---------------------------------------------------------------------------
-- friendships: accepted relationships, stored MIRRORED (two rows per pair).
-- A<->B friends => rows (A,B) and (B,A). Lets "is X my friend?" be a single
-- (user_id = me, friend_id = X) lookup, which keeps RLS policies simple/fast.
-- Mutated only by security-definer RPCs, never by the client directly.
-- ---------------------------------------------------------------------------
create table public.friendships (
    user_id    uuid not null references public.profiles (id) on delete cascade,
    friend_id  uuid not null references public.profiles (id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, friend_id),
    constraint friendships_distinct check (user_id <> friend_id)
);

create index friendships_friend_id_idx on public.friendships (friend_id);
