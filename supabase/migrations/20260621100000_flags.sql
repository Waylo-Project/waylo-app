-- Flag tier (zoomed-out map): each post gets a country, and a per-country
-- aggregate RPC powers the flag markers.
--   * posts.country_code: ISO 3166-1 alpha-2 (lowercase), reverse-geocoded by
--     the client at post time. Matches the bundled flag asset filenames.
--   * flags_in_view: per-country count + centroid of the caller's visible posts.

set search_path = public, extensions;

alter table public.posts add column if not exists country_code text;

-- create_post gains p_country_code. Drop the old 5-arg signature so there is
-- only one create_post.
drop function if exists public.create_post(
    double precision, double precision, text, timestamptz, text[]);

create or replace function public.create_post(
    p_lng         double precision,
    p_lat         double precision,
    p_caption     text,
    p_taken_at    timestamptz,
    p_image_paths text[],
    p_country_code text
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

    insert into public.posts (user_id, location, caption, taken_at, country_code)
    values (
        v_me,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_caption,
        p_taken_at,
        p_country_code
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

revoke all on function public.create_post(
    double precision, double precision, text, timestamptz, text[], text) from public;
grant execute on function public.create_post(
    double precision, double precision, text, timestamptz, text[], text) to authenticated;

-- ---------------------------------------------------------------------------
-- flags_in_view: per-country count + centroid of posts visible to the caller
-- inside a bounding box. SECURITY INVOKER -> RLS applies (own + friends).
-- ---------------------------------------------------------------------------
create or replace function public.flags_in_view(
    min_lng double precision,
    min_lat double precision,
    max_lng double precision,
    max_lat double precision
)
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
      and ST_Intersects(
          p.location,
          ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat, 4326)::geography
      )
    group by p.country_code;
$$;

revoke all on function public.flags_in_view(
    double precision, double precision, double precision, double precision) from public;
grant execute on function public.flags_in_view(
    double precision, double precision, double precision, double precision) to authenticated;
