-- Localize push notifications: remember each device's app language so the
-- send_push Edge Function can compose the message in the recipient's language
-- (ko / en). A device defaults to English if it never reports a language.

set search_path = public, extensions;

alter table public.device_tokens
    add column if not exists language text not null default 'en';

-- register_device_token gains p_language. Drop the old 2-arg signature and
-- recreate with the extra (defaulted) parameter so existing 2-arg callers still
-- work while the app sends the language.
drop function if exists public.register_device_token(text, text);

create or replace function public.register_device_token(
    p_token    text,
    p_platform text default 'android',
    p_language text default 'en'
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
    delete from public.device_tokens
    where token = p_token and user_id <> auth.uid();

    insert into public.device_tokens (token, user_id, platform, language, updated_at)
    values (p_token, auth.uid(), p_platform, p_language, now())
    on conflict (token) do update
        set user_id = excluded.user_id,
            platform = excluded.platform,
            language = excluded.language,
            updated_at = now();
end;
$$;

revoke all on function public.register_device_token(text, text, text) from public;
grant execute on function public.register_device_token(text, text, text) to authenticated;
