-- Push notifications (Phase 8): per-device FCM tokens, so the send_push Edge
-- Function can look up where to deliver a user's notifications.
--
-- A token identifies one device install and maps to exactly ONE user at a time
-- (reinstall / account switch reassigns it). register_device_token() is
-- SECURITY DEFINER so it can reclaim a token from a previous owner (RLS would
-- otherwise block deleting another user's row); every other access is the
-- caller's own rows only.

set search_path = public, extensions;

create table public.device_tokens (
    token      text primary key,
    user_id    uuid not null references public.profiles (id) on delete cascade,
    platform   text not null default 'android',
    updated_at timestamptz not null default now()
);

create index device_tokens_user_id_idx on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

-- A user can read / drop their own device rows (e.g. on sign-out). Writes go
-- through register_device_token() below.
create policy device_tokens_select_own on public.device_tokens
    for select to authenticated using (user_id = auth.uid());

create policy device_tokens_delete_own on public.device_tokens
    for delete to authenticated using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- register_device_token: upsert the caller's FCM token, reclaiming it from any
-- previous owner so a shared device never delivers to the wrong account.
-- ---------------------------------------------------------------------------
create or replace function public.register_device_token(
    p_token    text,
    p_platform text default 'android'
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
    delete from public.device_tokens
    where token = p_token and user_id <> auth.uid();

    insert into public.device_tokens (token, user_id, platform, updated_at)
    values (p_token, auth.uid(), p_platform, now())
    on conflict (token) do update
        set user_id = excluded.user_id,
            platform = excluded.platform,
            updated_at = now();
end;
$$;

revoke all on function public.register_device_token(text, text) from public;
grant execute on function public.register_device_token(text, text) to authenticated;
