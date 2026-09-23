-- Place label: an optional place name the poster wrote themselves (e.g.
-- "Grandma's café"). The post screen auto-fills a reverse-geocoded name; that
-- auto name is NOT stored (null), so each viewer keeps seeing it geocoded in
-- their own language. Only a name the poster edited is saved, and shown as
-- written.
--
-- create_post / update_post gain p_place_label (default null, so an app build
-- that doesn't send it still works). The old signatures are dropped so each
-- function has exactly one overload. Owner checks are unchanged.

set search_path = public, extensions;

alter table public.posts
    add column if not exists place_label text
    constraint posts_place_label_length check (char_length(place_label) <= 100);

-- ---------------------------------------------------------------------------
-- create_post
-- ---------------------------------------------------------------------------
drop function if exists public.create_post(
    double precision, double precision, text, timestamptz, text[], text);

create or replace function public.create_post(
    p_lng          double precision,
    p_lat          double precision,
    p_caption      text,
    p_taken_at     timestamptz,
    p_image_paths  text[],
    p_country_code text,
    p_place_label  text default null
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

    insert into public.posts (user_id, location, caption, taken_at, country_code, place_label)
    values (
        v_me,
        ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
        p_caption,
        p_taken_at,
        p_country_code,
        nullif(btrim(p_place_label), '')
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
    double precision, double precision, text, timestamptz, text[], text, text) from public;
grant execute on function public.create_post(
    double precision, double precision, text, timestamptz, text[], text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- update_post
-- ---------------------------------------------------------------------------
drop function if exists public.update_post(
    uuid, double precision, double precision, text, timestamptz, text);

create or replace function public.update_post(
    p_post_id      uuid,
    p_lng          double precision,
    p_lat          double precision,
    p_caption      text,
    p_taken_at     timestamptz,
    p_country_code text,
    p_place_label  text default null
)
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

    update public.posts
       set location     = ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
           caption      = p_caption,
           taken_at     = p_taken_at,
           country_code = p_country_code,
           place_label  = nullif(btrim(p_place_label), '')
     where id = p_post_id
       and user_id = v_me;

    if not found then
        raise exception 'post % not found or not owned by caller', p_post_id;
    end if;
end;
$$;

revoke all on function public.update_post(
    uuid, double precision, double precision, text, timestamptz, text, text) from public;
grant execute on function public.update_post(
    uuid, double precision, double precision, text, timestamptz, text, text) to authenticated;
