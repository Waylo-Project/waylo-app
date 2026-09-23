-- RPC functions for multi-row / atomic operations.
-- These are SECURITY DEFINER (they run as the function owner and bypass RLS),
-- so each one re-derives the caller from auth.uid() and validates authorization
-- itself. Execution is granted to authenticated only.

set search_path = public, extensions;

-- ---------------------------------------------------------------------------
-- create_post: insert one post + its photos atomically.
-- Photo paths must live under the caller's own Storage folder ({uid}/...).
-- ---------------------------------------------------------------------------
create or replace function public.create_post(
    p_lng        double precision,
    p_lat        double precision,
    p_caption    text,
    p_taken_at   timestamptz,
    p_image_paths text[]
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_me      uuid := auth.uid();
    v_post_id uuid;
    v_path    text;
    v_pos     int := 0;
begin
    if v_me is null then
        raise exception 'not authenticated';
    end if;
    if p_image_paths is null or array_length(p_image_paths, 1) is null then
        raise exception 'at least one photo is required';
    end if;

    insert into public.posts (user_id, location, caption, taken_at)
    values (
        v_me,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_caption,
        p_taken_at
    )
    returning id into v_post_id;

    foreach v_path in array p_image_paths loop
        if v_path not like v_me::text || '/%' then
            raise exception 'image path % is not under the caller folder', v_path;
        end if;
        insert into public.post_photos (post_id, image_path, position)
        values (v_post_id, v_path, v_pos);
        v_pos := v_pos + 1;
    end loop;

    return v_post_id;
end;
$$;

revoke all on function public.create_post(double precision, double precision, text, timestamptz, text[]) from public;
grant execute on function public.create_post(double precision, double precision, text, timestamptz, text[]) to authenticated;

-- ---------------------------------------------------------------------------
-- send_friend_request: send a request, with guards.
--   - rejects self / already-friends
--   - if the other user already has a pending request to me, auto-accepts it
--   - otherwise inserts (or re-opens a previously declined) request
-- ---------------------------------------------------------------------------
create or replace function public.send_friend_request(p_to_user uuid)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_me      uuid := auth.uid();
    v_id      uuid;
    v_reverse public.friend_requests%rowtype;
begin
    if v_me is null then
        raise exception 'not authenticated';
    end if;
    if p_to_user = v_me then
        raise exception 'cannot send a friend request to yourself';
    end if;
    if exists (
        select 1 from public.friendships
        where user_id = v_me and friend_id = p_to_user
    ) then
        raise exception 'already friends';
    end if;

    -- Reverse pending request -> accept it instead of creating a new one.
    select * into v_reverse from public.friend_requests
    where from_user = p_to_user and to_user = v_me and status = 'pending';
    if found then
        update public.friend_requests
        set status = 'accepted', updated_at = now()
        where id = v_reverse.id;
        insert into public.friendships (user_id, friend_id)
        values (v_me, p_to_user) on conflict do nothing;
        insert into public.friendships (user_id, friend_id)
        values (p_to_user, v_me) on conflict do nothing;
        return v_reverse.id;
    end if;

    insert into public.friend_requests (from_user, to_user)
    values (v_me, p_to_user)
    on conflict (from_user, to_user)
        do update set status = 'pending', updated_at = now()
    returning id into v_id;

    return v_id;
end;
$$;

revoke all on function public.send_friend_request(uuid) from public;
grant execute on function public.send_friend_request(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- respond_to_friend_request: accept or decline a pending request addressed to
-- the caller. On accept, creates the mirrored friendship rows atomically.
-- ---------------------------------------------------------------------------
create or replace function public.respond_to_friend_request(
    p_request_id uuid,
    p_accept     boolean
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_me uuid := auth.uid();
    r    public.friend_requests%rowtype;
begin
    if v_me is null then
        raise exception 'not authenticated';
    end if;

    select * into r from public.friend_requests where id = p_request_id for update;
    if not found then
        raise exception 'friend request not found';
    end if;
    if r.to_user <> v_me then
        raise exception 'not authorized to respond to this request';
    end if;
    if r.status <> 'pending' then
        raise exception 'friend request already handled';
    end if;

    if p_accept then
        update public.friend_requests
        set status = 'accepted', updated_at = now()
        where id = r.id;
        insert into public.friendships (user_id, friend_id)
        values (r.from_user, r.to_user) on conflict do nothing;
        insert into public.friendships (user_id, friend_id)
        values (r.to_user, r.from_user) on conflict do nothing;
    else
        update public.friend_requests
        set status = 'declined', updated_at = now()
        where id = r.id;
    end if;
end;
$$;

revoke all on function public.respond_to_friend_request(uuid, boolean) from public;
grant execute on function public.respond_to_friend_request(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- remove_friend: delete both mirrored rows for a friendship with the caller.
-- ---------------------------------------------------------------------------
create or replace function public.remove_friend(p_friend_id uuid)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_me uuid := auth.uid();
begin
    if v_me is null then
        raise exception 'not authenticated';
    end if;
    delete from public.friendships
    where (user_id = v_me and friend_id = p_friend_id)
       or (user_id = p_friend_id and friend_id = v_me);
end;
$$;

revoke all on function public.remove_friend(uuid) from public;
grant execute on function public.remove_friend(uuid) to authenticated;
