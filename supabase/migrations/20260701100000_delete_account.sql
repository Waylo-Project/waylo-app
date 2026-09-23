-- delete_account: permanently delete the caller's own account.
--
-- SECURITY DEFINER (runs as the function owner), so it can remove the row from
-- auth.users — which cascades through every table keyed on the user
-- (profiles -> posts -> post_photos / post_likes / post_comments,
--  friend_requests, friendships, device_tokens) via the ON DELETE CASCADE
-- foreign keys defined in the schema. The actor is derived from auth.uid(),
-- never from a parameter, so a caller can only ever delete themselves.
--
-- Storage objects are NOT reached by the table cascade, so we delete the user's
-- own files first (paths are `{uid}/...` in both buckets, enforced at upload).

set search_path = public, extensions;

create or replace function public.delete_account()
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

    -- Remove the user's Storage files (private photos + public avatars).
    delete from storage.objects
     where bucket_id in ('photos', 'avatars')
       and name like v_me::text || '/%';

    -- Deleting the auth user cascades to the profile and everything under it.
    delete from auth.users where id = v_me;
end;
$$;

revoke all on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
