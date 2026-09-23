-- Per-user maps: each user's map shows only that user's posts (you view a
-- friend's photos on the friend's own map, not merged into yours). The map
-- queries take a target user id; RLS (SECURITY INVOKER) still ensures you only
-- get posts you're allowed to see, so a non-friend id returns nothing.

set search_path = public, extensions;

-- posts_in_view gains p_user_id: only that user's posts in the box.
drop function if exists public.posts_in_view(
    double precision, double precision, double precision, double precision);

create or replace function public.posts_in_view(
    min_lng    double precision,
    min_lat    double precision,
    max_lng    double precision,
    max_lat    double precision,
    p_user_id  uuid
)
returns table (
    post_id    uuid,
    owner_id   uuid,
    lng        double precision,
    lat        double precision,
    image_path text,
    created_at timestamptz
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
    select
        p.id,
        p.user_id,
        ST_X(p.location::geometry),
        ST_Y(p.location::geometry),
        ph.image_path,
        p.created_at
    from public.posts p
    join lateral (
        select image_path
        from public.post_photos
        where post_id = p.id
        order by position asc
        limit 1
    ) ph on true
    where p.user_id = p_user_id
      and ST_Intersects(
          p.location,
          ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)::geography
      );
$$;

revoke all on function public.posts_in_view(
    double precision, double precision, double precision, double precision, uuid)
    from public;
grant execute on function public.posts_in_view(
    double precision, double precision, double precision, double precision, uuid)
    to authenticated;

-- Per-user flag aggregate; replaces flags_all / flags_in_view.
drop function if exists public.flags_all();
drop function if exists public.flags_in_view(
    double precision, double precision, double precision, double precision);

create or replace function public.flags_for_user(p_user_id uuid)
returns table (
    country_code text,
    post_count   bigint,
    lng          double precision,
    lat          double precision
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
    select
        p.country_code,
        count(*),
        avg(ST_X(p.location::geometry)),
        avg(ST_Y(p.location::geometry))
    from public.posts p
    where p.user_id = p_user_id
      and p.country_code is not null
    group by p.country_code;
$$;

revoke all on function public.flags_for_user(uuid) from public;
grant execute on function public.flags_for_user(uuid) to authenticated;
