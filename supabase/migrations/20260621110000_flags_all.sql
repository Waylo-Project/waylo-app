-- flags_all: per-country count + centroid of ALL posts visible to the caller,
-- with no bounding box. The zoomed-out flag tier is a whole-world overview, and
-- a full-globe geography envelope trips PostGIS ("Antipodal edge detected"), so
-- the flag tier uses this instead of flags_in_view.
-- SECURITY INVOKER -> RLS applies (own + accepted friends).

set search_path = public, extensions;

create or replace function public.flags_all()
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
    where p.country_code is not null
    group by p.country_code;
$$;

revoke all on function public.flags_all() from public;
grant execute on function public.flags_all() to authenticated;
