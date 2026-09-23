-- Row Level Security for all waylo tables.
-- Access control is enforced here, not in the client. Every table is locked
-- down; the photo visibility rule (owner + accepted friends) lives in posts /
-- post_photos SELECT policies.

set search_path = public, extensions;

alter table public.profiles        enable row level security;
alter table public.posts           enable row level security;
alter table public.post_photos     enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships     enable row level security;

-- ---------------------------------------------------------------------------
-- profiles: readable by any signed-in user (needed for friend search and to
-- show friends' names/avatars). Writable only by the owner.
-- ---------------------------------------------------------------------------
create policy profiles_select_authenticated on public.profiles
    for select to authenticated using (true);

create policy profiles_insert_own on public.profiles
    for insert to authenticated with check (id = auth.uid());

create policy profiles_update_own on public.profiles
    for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy profiles_delete_own on public.profiles
    for delete to authenticated using (id = auth.uid());

-- ---------------------------------------------------------------------------
-- posts: visible to the owner OR the owner's accepted friends. Written by owner.
-- ---------------------------------------------------------------------------
create policy posts_select_self_or_friend on public.posts
    for select to authenticated using (
        user_id = auth.uid()
        or exists (
            select 1 from public.friendships f
            where f.user_id = auth.uid() and f.friend_id = posts.user_id
        )
    );

create policy posts_insert_own on public.posts
    for insert to authenticated with check (user_id = auth.uid());

create policy posts_update_own on public.posts
    for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy posts_delete_own on public.posts
    for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- post_photos: visible whenever the parent post is visible; written only by
-- the post's owner.
-- ---------------------------------------------------------------------------
create policy post_photos_select_visible on public.post_photos
    for select to authenticated using (
        exists (
            select 1 from public.posts p
            where p.id = post_photos.post_id
              and (
                  p.user_id = auth.uid()
                  or exists (
                      select 1 from public.friendships f
                      where f.user_id = auth.uid() and f.friend_id = p.user_id
                  )
              )
        )
    );

create policy post_photos_insert_own on public.post_photos
    for insert to authenticated with check (
        exists (
            select 1 from public.posts p
            where p.id = post_photos.post_id and p.user_id = auth.uid()
        )
    );

create policy post_photos_delete_own on public.post_photos
    for delete to authenticated using (
        exists (
            select 1 from public.posts p
            where p.id = post_photos.post_id and p.user_id = auth.uid()
        )
    );

-- ---------------------------------------------------------------------------
-- friend_requests: a user sees requests they sent or received, can send as
-- themselves, and can cancel ones they sent. Status changes (accept/decline)
-- go through respond_to_friend_request() only -- no direct UPDATE policy.
-- ---------------------------------------------------------------------------
create policy friend_requests_select_involved on public.friend_requests
    for select to authenticated using (
        from_user = auth.uid() or to_user = auth.uid()
    );

create policy friend_requests_insert_sender on public.friend_requests
    for insert to authenticated with check (from_user = auth.uid());

create policy friend_requests_delete_sender on public.friend_requests
    for delete to authenticated using (from_user = auth.uid());

-- ---------------------------------------------------------------------------
-- friendships: a user can read rows they belong to. No client INSERT/UPDATE/
-- DELETE -- friendships are created/removed only via security-definer RPCs.
-- ---------------------------------------------------------------------------
create policy friendships_select_involved on public.friendships
    for select to authenticated using (
        user_id = auth.uid() or friend_id = auth.uid()
    );
