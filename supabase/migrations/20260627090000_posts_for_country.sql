-- Tapping a country flag should frame that country's ACTUAL posts, not the
-- geographic country center. The flag sits at the country center (intentional),
-- but the posts can be far from it -- flying to the center at a fixed zoom can
-- leave every photo off-screen (empty map). This returns just the coordinates
-- of a user's posts in one country; the client computes the camera (fit the
-- bounding box, or center on the densest cluster when the posts are too spread
-- out to fit without dropping back to the flag tier).
--
-- SECURITY INVOKER so RLS still limits rows to posts the caller may see (own, or
-- a friend's) -- a non-friend target id returns nothing.

set search_path = public, extensions;

create or replace function public.posts_for_country(
    p_user_id      uuid,
    p_country_code text
)
returns table (
    lng double precision,
    lat double precision
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
    select
        ST_X(p.location::geometry),
        ST_Y(p.location::geometry)
    from public.posts p
    where p.user_id = p_user_id
      and p.country_code = p_country_code;
$$;

revoke all on function public.posts_for_country(uuid, text) from public;
grant execute on function public.posts_for_country(uuid, text) to authenticated;
