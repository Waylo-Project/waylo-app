-- Friends-screen redesign metadata:
--   * friend_countries(): the "passport strip" — distinct country codes per
--     friend, with a post count so the client can order + cap them.
--   * incoming_requests_with_mutuals(): incoming requests joined with the
--     mutual-friend context shown on each request card.
-- Both derive the actor from auth.uid(); neither trusts a client-supplied id.

set search_path = public, extensions;

-- ---------------------------------------------------------------------------
-- friend_countries: for each accepted friend, the distinct countries they have
-- posted in, with a count. SECURITY INVOKER -> the posts SELECT policy (own +
-- friends) already scopes this to people I'm allowed to see; the explicit
-- friendships EXISTS keeps it to *my* friends only (not my own posts).
-- ---------------------------------------------------------------------------
create or replace function public.friend_countries()
returns table (
    friend_id    uuid,
    country_code text,
    post_count   bigint
)
language sql
stable
security invoker
set search_path = public, extensions
as $$
    select p.user_id, p.country_code, count(*)
    from public.posts p
    where p.country_code is not null
      and exists (
          select 1 from public.friendships f
          where f.user_id = auth.uid() and f.friend_id = p.user_id
      )
    group by p.user_id, p.country_code;
$$;

revoke all on function public.friend_countries() from public;
grant execute on function public.friend_countries() to authenticated;

-- ---------------------------------------------------------------------------
-- incoming_requests_with_mutuals: my pending incoming requests, each with the
-- count and a small sample of mutual friends. SECURITY DEFINER because it must
-- read the *sender's* friendships (RLS would otherwise hide them). It is safe:
--   * reqs is filtered to to_user = auth.uid() (only my own incoming requests);
--   * a "mutual" is someone who is a friend of the sender AND a friend of mine,
--     so every username returned is already one of my own friends -> no new
--     disclosure about the sender's other friends.
-- ---------------------------------------------------------------------------
create or replace function public.incoming_requests_with_mutuals()
returns table (
    request_id       uuid,
    from_user        uuid,
    username         text,
    avatar_path      text,
    mutual_count     bigint,
    mutual_usernames text[]
)
language sql
stable
security definer
set search_path = public, extensions
as $$
    with me as (
        select auth.uid() as uid
    ),
    reqs as (
        select fr.id as request_id, fr.from_user
        from public.friend_requests fr, me
        where fr.to_user = me.uid
          and fr.status = 'pending'
    ),
    muts as (
        select r.request_id, mp.username
        from reqs r
        join public.friendships sf
            on sf.user_id = r.from_user            -- the sender's friends
        join public.friendships mf
            on mf.user_id = (select uid from me)   -- ...that are also my friends
           and mf.friend_id = sf.friend_id
        join public.profiles mp
            on mp.id = sf.friend_id
    )
    select
        r.request_id,
        r.from_user,
        pr.username,
        pr.avatar_path,
        count(m.username) as mutual_count,
        (array_agg(m.username order by m.username)
            filter (where m.username is not null))[1:3] as mutual_usernames
    from reqs r
    join public.profiles pr on pr.id = r.from_user
    left join muts m on m.request_id = r.request_id
    group by r.request_id, r.from_user, pr.username, pr.avatar_path;
$$;

revoke all on function public.incoming_requests_with_mutuals() from public;
grant execute on function public.incoming_requests_with_mutuals() to authenticated;
