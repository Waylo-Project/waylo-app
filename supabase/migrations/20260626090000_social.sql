-- Social layer for the photo sheet: likes + comments, plus the "Recent" (last
-- 24h) merged-friends feed.
--
-- Visibility piggybacks on the existing photo model: you may like/comment on a
-- post exactly when you can SEE it (own or an accepted friend's). Rather than
-- re-derive the friendship EXISTS in four policies, can_see_post() leans on the
-- posts SELECT RLS: under SECURITY INVOKER, `select 1 from posts where id = ?`
-- returns a row only if the caller is allowed to see that post.

set search_path = public, extensions;

-- ---------------------------------------------------------------------------
-- can_see_post: true when the caller may see the post. Runs as the caller
-- (SECURITY INVOKER) so the posts SELECT policy does the visibility work.
-- ---------------------------------------------------------------------------
create or replace function public.can_see_post(p_post_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = public, extensions
as $$
    select exists (select 1 from public.posts where id = p_post_id);
$$;

revoke all on function public.can_see_post(uuid) from public;
grant execute on function public.can_see_post(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- post_likes: one row per (post, liker). A like exists or it doesn't.
-- ---------------------------------------------------------------------------
create table public.post_likes (
    post_id    uuid not null references public.posts (id) on delete cascade,
    user_id    uuid not null references public.profiles (id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (post_id, user_id)
);

create index post_likes_post_id_idx on public.post_likes (post_id);

alter table public.post_likes enable row level security;

create policy post_likes_select_visible on public.post_likes
    for select to authenticated using (public.can_see_post(post_id));

create policy post_likes_insert_self on public.post_likes
    for insert to authenticated
    with check (user_id = auth.uid() and public.can_see_post(post_id));

create policy post_likes_delete_self on public.post_likes
    for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- post_comments: a flat list of comments on a post (guestbook style, no
-- threading). Editing a comment isn't supported; deleting is.
-- ---------------------------------------------------------------------------
create table public.post_comments (
    id         uuid primary key default gen_random_uuid(),
    post_id    uuid not null references public.posts (id) on delete cascade,
    user_id    uuid not null references public.profiles (id) on delete cascade,
    body       text not null check (char_length(body) between 1 and 500),
    created_at timestamptz not null default now()
);

create index post_comments_post_id_idx on public.post_comments (post_id, created_at);

alter table public.post_comments enable row level security;

create policy post_comments_select_visible on public.post_comments
    for select to authenticated using (public.can_see_post(post_id));

create policy post_comments_insert_self on public.post_comments
    for insert to authenticated
    with check (user_id = auth.uid() and public.can_see_post(post_id));

-- The comment author can delete their own comment; the post owner can delete
-- any comment on their post (moderate their own guestbook).
create policy post_comments_delete_own_or_postowner on public.post_comments
    for delete to authenticated using (
        user_id = auth.uid()
        or exists (
            select 1 from public.posts p
            where p.id = post_comments.post_id and p.user_id = auth.uid()
        )
    );

-- ---------------------------------------------------------------------------
-- recent_feed: every accepted friend's posts from the last 24h, newest first,
-- with the author's profile and the post's first photo. No bounding box -- the
-- set is small (time-limited) and the client fits the map to it, which also
-- avoids the full-globe PostGIS envelope issue (see flags_for_user).
--
-- SECURITY INVOKER: posts RLS limits this to the caller's friends already; the
-- explicit `user_id <> auth.uid()` just drops the caller's own posts (those
-- live on the home map).
-- ---------------------------------------------------------------------------
create or replace function public.recent_feed()
returns table (
    post_id     uuid,
    owner_id    uuid,
    username    text,
    avatar_path text,
    lng         double precision,
    lat         double precision,
    image_path  text,
    created_at  timestamptz
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
    select
        p.id,
        p.user_id,
        pr.username,
        pr.avatar_path,
        ST_X(p.location::geometry),
        ST_Y(p.location::geometry),
        ph.image_path,
        p.created_at
    from public.posts p
    join public.profiles pr on pr.id = p.user_id
    join lateral (
        select image_path
        from public.post_photos
        where post_id = p.id
        order by position asc
        limit 1
    ) ph on true
    where p.user_id <> auth.uid()
      and p.created_at >= now() - interval '24 hours'
    order by p.created_at desc;
$$;

revoke all on function public.recent_feed() from public;
grant execute on function public.recent_feed() to authenticated;
