-- posts_in_view: the posts visible to the caller within a map bounding box,
-- with the first photo's storage path and plain lng/lat (geography is awkward
-- to read over PostgREST). Powers the map's viewport-based marker fetch.
--
-- SECURITY INVOKER (default): RLS on posts / post_photos applies to the caller,
-- so this returns the caller's own posts now and, once friendships exist, their
-- accepted friends' posts too -- no change needed for Phase 4.

set search_path = public, extensions;

create or replace function public.posts_in_view(
    min_lng double precision,
    min_lat double precision,
    max_lng double precision,
    max_lat double precision
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
    where ST_Intersects(
        p.location,
        ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)::geography
    );
$$;

revoke all on function public.posts_in_view(
    double precision, double precision, double precision, double precision
) from public;
grant execute on function public.posts_in_view(
    double precision, double precision, double precision, double precision
) to authenticated;
