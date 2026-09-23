-- One level of threaded replies on comments. The guestbook stays flat at the
-- top level; a comment may carry replies, but a reply cannot itself be replied
-- to (Instagram/Threads model, not Reddit). Depth and same-post integrity are
-- enforced by a trigger so the client can't create an illegal tree.
--
-- Visibility is unchanged: replies live in post_comments, so the existing
-- post_comments RLS (can_see_post + author/post-owner delete) already covers
-- them. A reply's parent is on the same post, so no new policy is needed.

set search_path = public, extensions;

alter table public.post_comments
    add column parent_id uuid references public.post_comments (id) on delete cascade;

-- Replies of a comment, oldest first.
create index post_comments_parent_id_idx
    on public.post_comments (parent_id, created_at);

-- ---------------------------------------------------------------------------
-- enforce_comment_reply_rules: on insert of a reply (parent_id not null),
-- require that the parent exists, sits on the same post, and is itself a
-- top-level comment (its parent_id is null). This caps threading at one level
-- and blocks cross-post replies.
-- ---------------------------------------------------------------------------
create or replace function public.enforce_comment_reply_rules()
returns trigger
language plpgsql
set search_path = public, extensions
as $$
declare
    parent_post   uuid;
    parent_parent uuid;
begin
    if new.parent_id is null then
        return new;
    end if;

    select post_id, parent_id
      into parent_post, parent_parent
      from public.post_comments
     where id = new.parent_id;

    if parent_post is null then
        raise exception 'parent comment % not found', new.parent_id;
    end if;
    if parent_post <> new.post_id then
        raise exception 'reply must be on the same post as its parent';
    end if;
    if parent_parent is not null then
        raise exception 'replies are limited to one level';
    end if;

    return new;
end;
$$;

create trigger enforce_comment_reply_rules
    before insert on public.post_comments
    for each row execute function public.enforce_comment_reply_rules();
