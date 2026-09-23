-- Storage buckets and their access policies.
--   photos  : private. Mirrors the post visibility rule (owner + friends).
--   avatars : public-read (low sensitivity); writable only by the owner.
-- Path convention: the first folder segment is always the owner's uid, e.g.
--   photos/{user_id}/{post_id}/{photo_id}.jpg
--   avatars/{user_id}/{file}

set search_path = public, extensions;

insert into storage.buckets (id, name, public)
values ('photos', 'photos', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- photos bucket
-- ---------------------------------------------------------------------------
create policy photos_insert_own on storage.objects
    for insert to authenticated with check (
        bucket_id = 'photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy photos_select_self_or_friend on storage.objects
    for select to authenticated using (
        bucket_id = 'photos'
        and (
            (storage.foldername(name))[1] = auth.uid()::text
            or exists (
                select 1 from public.friendships f
                where f.user_id = auth.uid()
                  and f.friend_id::text = (storage.foldername(name))[1]
            )
        )
    );

create policy photos_delete_own on storage.objects
    for delete to authenticated using (
        bucket_id = 'photos'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

-- ---------------------------------------------------------------------------
-- avatars bucket (public read; owner-only writes)
-- ---------------------------------------------------------------------------
create policy avatars_insert_own on storage.objects
    for insert to authenticated with check (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy avatars_update_own on storage.objects
    for update to authenticated using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );

create policy avatars_delete_own on storage.objects
    for delete to authenticated using (
        bucket_id = 'avatars'
        and (storage.foldername(name))[1] = auth.uid()::text
    );
