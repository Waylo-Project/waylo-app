-- update_post: edit an existing post the caller owns (location, caption, date,
-- and the reverse-geocoded country code for the flag tier).
--
-- Mirrors create_post: SECURITY DEFINER with the actor derived from auth.uid(),
-- and the geography value built server-side from lng/lat (the client can't
-- construct a PostGIS geography). The WHERE clause pins the update to the
-- caller's own row, so a caller can only ever edit their own post; a missing /
-- unowned id raises instead of silently updating nothing.

set search_path = public, extensions;

create or replace function public.update_post(
    p_post_id      uuid,
    p_lng          double precision,
    p_lat          double precision,
    p_caption      text,
    p_taken_at     timestamptz,
    p_country_code text
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
           country_code = p_country_code
     where id = p_post_id
       and user_id = v_me;

    if not found then
        raise exception 'post % not found or not owned by caller', p_post_id;
    end if;
end;
$$;

revoke all on function public.update_post(uuid, double precision, double precision, text, timestamptz, text) from public;
grant execute on function public.update_post(uuid, double precision, double precision, text, timestamptz, text) to authenticated;
