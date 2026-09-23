-- Extra profile fields collected at sign-up: gender and birth date.
-- (display_name and avatar_path already exist on profiles.)

alter table public.profiles
    add column if not exists gender     text,
    add column if not exists birth_date date;
