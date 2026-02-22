create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  sober_start_date timestamptz not null,
  habit_name text not null,
  habit_custom_name text null,
  daily_spend numeric null,
  daily_time_spent integer null,
  motivation_text text null,
  motivation_photo_url text null,
  -- Public alias shown in community UI (never an email/name).
  alias text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists alias text;

-- Backfill a stable default alias.
update public.profiles
set alias = coalesce(
  nullif(alias, ''),
  'SoberFriend#' || substring(replace(id::text, '-', '') from 1 for 4)
)
where alias is null or alias = '';

alter table public.profiles
  alter column alias set default 'Anon',
  alter column alias set not null;

create table if not exists public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  entry_date timestamptz not null default now(),
  content text not null,
  mood text null,
  photo_url text null,
  created_at timestamptz not null default now()
);

alter table public.journal_entries
  add column if not exists audio_url text null,
  add column if not exists transcript text null;

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  anonymous_name text not null,
  content text not null,
  likes integer not null default 0,
  reaction_strength integer not null default 0,
  reaction_celebrate integer not null default 0,
  created_at timestamptz not null default now()
);

alter table public.community_posts
  add column if not exists reaction_strength integer not null default 0,
  add column if not exists reaction_celebrate integer not null default 0;

alter table public.community_posts
  add column if not exists alias text,
  add column if not exists message text,
  -- Legacy compatibility: older tables may have only `alias`/`message`.
  add column if not exists anonymous_name text,
  add column if not exists content text,
  add column if not exists likes integer not null default 0,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists category text null,
  add column if not exists topic text null,
  add column if not exists badge text null,
  add column if not exists streak_days integer null,
  add column if not exists streak_label text null,
  add column if not exists reply_count integer not null default 0;

update public.community_posts
  set anonymous_name = coalesce(anonymous_name, alias)
  where anonymous_name is null;

update public.community_posts
  set content = coalesce(content, message)
  where content is null;

-- Ensure required fields are never NULL before enforcing constraints.
update public.community_posts
  set anonymous_name = 'Anon'
  where anonymous_name is null;

update public.community_posts
  set content = ''
  where content is null;

alter table public.community_posts
  alter column anonymous_name set not null,
  alter column content set not null,
  alter column alias drop not null,
  alter column message drop not null;

-- Best-effort backfill for topic/streak on existing rows.
update public.community_posts p
set topic = coalesce(
    p.topic,
    pr.habit_custom_name,
    pr.habit_name
  ),
  streak_days = coalesce(
    p.streak_days,
    greatest(
      floor(extract(epoch from (p.created_at - pr.sober_start_date)) / 86400)::int + 1,
      0
    )
  ),
  streak_label = coalesce(
    p.streak_label,
    case
      when p.category = 'relapse' then 'Reset'
      else
        'Day ' ||
        greatest(
          floor(extract(epoch from (p.created_at - pr.sober_start_date)) / 86400)::int + 1,
          0
        )::text
    end
  )
from public.profiles pr
where pr.id = p.user_id;

do $$
declare
  post_id_type text;
begin
  select data_type
  into post_id_type
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'community_posts'
    and column_name = 'id';

  if post_id_type = 'bigint' then
    execute $sql$
      create table if not exists public.community_replies (
        id uuid primary key default gen_random_uuid(),
        post_id bigint not null references public.community_posts (id) on delete cascade,
        user_id uuid not null references public.profiles (id) on delete cascade,
        anonymous_name text not null,
        content text not null,
        created_at timestamptz not null default now()
      );
    $sql$;
  else
    execute $sql$
      create table if not exists public.community_replies (
        id uuid primary key default gen_random_uuid(),
        post_id uuid not null references public.community_posts (id) on delete cascade,
        user_id uuid not null references public.profiles (id) on delete cascade,
        anonymous_name text not null,
        content text not null,
        created_at timestamptz not null default now()
      );
    $sql$;
  end if;
end $$;

alter table public.community_replies
  add column if not exists anonymous_name text,
  add column if not exists content text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists alias text,
  add column if not exists message text;

update public.community_replies
  set anonymous_name = coalesce(anonymous_name, alias)
  where anonymous_name is null;

update public.community_replies
  set content = coalesce(content, message)
  where content is null;

update public.community_replies
  set anonymous_name = 'Anon'
  where anonymous_name is null;

update public.community_replies
  set content = ''
  where content is null;

alter table public.community_replies
  alter column anonymous_name set not null,
  alter column content set not null,
  alter column alias drop not null,
  alter column message drop not null;

create or replace function public.community_replies_inc_count()
returns trigger
language plpgsql
as $$
begin
  update public.community_posts
    set reply_count = reply_count + 1
  where id = new.post_id;
  return new;
end;
$$;

create or replace function public.community_replies_dec_count()
returns trigger
language plpgsql
as $$
begin
  update public.community_posts
    set reply_count = greatest(reply_count - 1, 0)
  where id = old.post_id;
  return old;
end;
$$;

drop trigger if exists trg_community_replies_inc_count on public.community_replies;
create trigger trg_community_replies_inc_count
after insert on public.community_replies
for each row execute function public.community_replies_inc_count();

drop trigger if exists trg_community_replies_dec_count on public.community_replies;
create trigger trg_community_replies_dec_count
after delete on public.community_replies
for each row execute function public.community_replies_dec_count();

-- Backfill reply_count for existing rows.
update public.community_posts p
set reply_count = coalesce(r.cnt, 0)
from (
  select post_id, count(*)::int as cnt
  from public.community_replies
  group by post_id
) r
where p.id = r.post_id;

create table if not exists public.dm_threads (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now()
);

create table if not exists public.dm_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.dm_threads (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.relapse_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  relapse_date timestamptz not null default now(),
  note text null,
  created_at timestamptz not null default now()
);

create table if not exists public.user_habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  habit_name text not null,
  habit_custom_name text null,
  sober_start_date timestamptz not null,
  daily_spend numeric null,
  daily_time_spent integer null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- `journal_entries.habit_id` references `user_habits`, so add it after the table exists.
alter table public.journal_entries
  add column if not exists habit_id uuid null references public.user_habits (id) on delete set null;

create table if not exists public.custom_milestones (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  target_value numeric null,
  current_value numeric null,
  unit text null,
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  completed_at timestamptz null
);

create table if not exists public.mood_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  mood text not null,
  note text null,
  logged_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.urge_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  habit_id uuid null references public.user_habits (id) on delete set null,
  intensity integer not null,
  trigger text null,
  note text null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text null,
  duration_days integer null,
  badge_image_url text null,
  is_active boolean not null default true
);

-- Community "Groups" are stored in `challenges` for now. Add metadata for creation/ownership.
alter table public.challenges
  add column if not exists kind text not null default 'group',
  add column if not exists created_by uuid null references public.profiles (id) on delete set null,
  add column if not exists created_at timestamptz not null default now();

create table if not exists public.user_challenges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  progress integer not null default 0,
  completed boolean not null default false,
  started_at timestamptz not null default now(),
  completed_at timestamptz null
);

-- Prevent duplicates so member counts stay correct.
create unique index if not exists idx_user_challenges_unique
  on public.user_challenges (user_id, challenge_id);

-- Group daily check-ins (members-only, anonymous UI in app).
create table if not exists public.group_checkins (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  note text null,
  checkin_date date not null default current_date,
  created_at timestamptz not null default now()
);

-- One check-in per user per group per day.
create unique index if not exists idx_group_checkins_unique
  on public.group_checkins (group_id, user_id, checkin_date);

-- Group chat messages (members-only).
create table if not exists public.group_messages (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.challenges (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now()
);

alter table public.challenges
  add column if not exists member_count integer not null default 0;

update public.challenges c
set member_count = coalesce(u.cnt, 0)
from (
  select challenge_id, count(*)::int as cnt
  from public.user_challenges
  group by challenge_id
) u
where c.id = u.challenge_id;

create or replace function public.user_challenges_inc_count()
returns trigger
language plpgsql
as $$
begin
  update public.challenges
    set member_count = member_count + 1
  where id = new.challenge_id;
  return new;
end;
$$;

create or replace function public.user_challenges_dec_count()
returns trigger
language plpgsql
as $$
begin
  update public.challenges
    set member_count = greatest(member_count - 1, 0)
  where id = old.challenge_id;
  return old;
end;
$$;

drop trigger if exists trg_user_challenges_inc_count on public.user_challenges;
create trigger trg_user_challenges_inc_count
after insert on public.user_challenges
for each row execute function public.user_challenges_inc_count();

drop trigger if exists trg_user_challenges_dec_count on public.user_challenges;
create trigger trg_user_challenges_dec_count
after delete on public.user_challenges
for each row execute function public.user_challenges_dec_count();

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text null,
  icon_url text null,
  criteria text null
);

create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  badge_id uuid not null references public.badges (id) on delete cascade,
  earned_at timestamptz not null default now()
);

create table if not exists public.daily_prompts (
  id uuid primary key default gen_random_uuid(),
  prompt_text text not null,
  category text null,
  is_premium boolean not null default false
);

create table if not exists public.support_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  contact_name text null,
  contact_phone text null,
  contact_email text null,
  relationship text null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.support_connections (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  message text not null,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.bump_dm_thread()
returns trigger
language plpgsql
as $$
begin
  update public.dm_threads
    set last_message_at = new.created_at
  where id = new.thread_id;
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.journal_entries enable row level security;
alter table public.community_posts enable row level security;
alter table public.community_replies enable row level security;
alter table public.relapse_logs enable row level security;
alter table public.user_habits enable row level security;
alter table public.custom_milestones enable row level security;
alter table public.mood_logs enable row level security;
alter table public.urge_logs enable row level security;
alter table public.challenges enable row level security;
alter table public.user_challenges enable row level security;
alter table public.group_checkins enable row level security;
alter table public.group_messages enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.daily_prompts enable row level security;
alter table public.support_connections enable row level security;
alter table public.support_messages enable row level security;
alter table public.dm_threads enable row level security;
alter table public.dm_messages enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists journal_entries_select_own on public.journal_entries;
create policy journal_entries_select_own
on public.journal_entries
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists journal_entries_insert_own on public.journal_entries;
create policy journal_entries_insert_own
on public.journal_entries
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists journal_entries_update_own on public.journal_entries;
create policy journal_entries_update_own
on public.journal_entries
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists journal_entries_delete_own on public.journal_entries;
create policy journal_entries_delete_own
on public.journal_entries
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists community_posts_read on public.community_posts;
create policy community_posts_read
on public.community_posts
for select
to authenticated
using (true);

drop policy if exists community_posts_insert on public.community_posts;
create policy community_posts_insert
on public.community_posts
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists community_posts_update_own on public.community_posts;
create policy community_posts_update_own
on public.community_posts
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists community_posts_delete_own on public.community_posts;
create policy community_posts_delete_own
on public.community_posts
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists community_replies_read on public.community_replies;
create policy community_replies_read
on public.community_replies
for select
to authenticated
using (true);

drop policy if exists community_replies_insert on public.community_replies;
create policy community_replies_insert
on public.community_replies
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists community_replies_update_own on public.community_replies;
create policy community_replies_update_own
on public.community_replies
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists community_replies_delete_own on public.community_replies;
create policy community_replies_delete_own
on public.community_replies
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists relapse_logs_select_own on public.relapse_logs;
create policy relapse_logs_select_own
on public.relapse_logs
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists relapse_logs_insert_own on public.relapse_logs;
create policy relapse_logs_insert_own
on public.relapse_logs
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists relapse_logs_update_own on public.relapse_logs;
create policy relapse_logs_update_own
on public.relapse_logs
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists relapse_logs_delete_own on public.relapse_logs;
create policy relapse_logs_delete_own
on public.relapse_logs
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists user_habits_select_own on public.user_habits;
create policy user_habits_select_own
on public.user_habits
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists user_habits_insert_own on public.user_habits;
create policy user_habits_insert_own
on public.user_habits
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists user_habits_update_own on public.user_habits;
create policy user_habits_update_own
on public.user_habits
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists user_habits_delete_own on public.user_habits;
create policy user_habits_delete_own
on public.user_habits
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists custom_milestones_select_own on public.custom_milestones;
create policy custom_milestones_select_own
on public.custom_milestones
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists custom_milestones_insert_own on public.custom_milestones;
create policy custom_milestones_insert_own
on public.custom_milestones
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists custom_milestones_update_own on public.custom_milestones;
create policy custom_milestones_update_own
on public.custom_milestones
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists custom_milestones_delete_own on public.custom_milestones;
create policy custom_milestones_delete_own
on public.custom_milestones
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists mood_logs_select_own on public.mood_logs;
create policy mood_logs_select_own
on public.mood_logs
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists mood_logs_insert_own on public.mood_logs;
create policy mood_logs_insert_own
on public.mood_logs
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists mood_logs_delete_own on public.mood_logs;
create policy mood_logs_delete_own
on public.mood_logs
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists urge_logs_select_own on public.urge_logs;
create policy urge_logs_select_own
on public.urge_logs
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists urge_logs_insert_own on public.urge_logs;
create policy urge_logs_insert_own
on public.urge_logs
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists urge_logs_delete_own on public.urge_logs;
create policy urge_logs_delete_own
on public.urge_logs
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists challenges_select on public.challenges;
create policy challenges_select
on public.challenges
for select
to authenticated
using (true);

drop policy if exists challenges_insert_own on public.challenges;
create policy challenges_insert_own
on public.challenges
for insert
to authenticated
with check (auth.uid() = created_by);

drop policy if exists challenges_update_own on public.challenges;
create policy challenges_update_own
on public.challenges
for update
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

drop policy if exists challenges_delete_own on public.challenges;
create policy challenges_delete_own
on public.challenges
for delete
to authenticated
using (auth.uid() = created_by);

drop policy if exists user_challenges_select_own on public.user_challenges;
create policy user_challenges_select_own
on public.user_challenges
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists user_challenges_insert_own on public.user_challenges;
create policy user_challenges_insert_own
on public.user_challenges
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists user_challenges_update_own on public.user_challenges;
create policy user_challenges_update_own
on public.user_challenges
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists group_checkins_select_member on public.group_checkins;
create policy group_checkins_select_member
on public.group_checkins
for select
to authenticated
using (
  exists (
    select 1
    from public.user_challenges uc
    where uc.challenge_id = group_id
      and uc.user_id = auth.uid()
  )
);

drop policy if exists group_checkins_insert_member on public.group_checkins;
create policy group_checkins_insert_member
on public.group_checkins
for insert
to authenticated
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.user_challenges uc
    where uc.challenge_id = group_id
      and uc.user_id = auth.uid()
  )
);

drop policy if exists group_checkins_delete_own on public.group_checkins;
create policy group_checkins_delete_own
on public.group_checkins
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists group_messages_select_member on public.group_messages;
create policy group_messages_select_member
on public.group_messages
for select
to authenticated
using (
  exists (
    select 1
    from public.user_challenges uc
    where uc.challenge_id = group_id
      and uc.user_id = auth.uid()
  )
);

drop policy if exists group_messages_insert_member on public.group_messages;
create policy group_messages_insert_member
on public.group_messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.user_challenges uc
    where uc.challenge_id = group_id
      and uc.user_id = auth.uid()
  )
);

drop policy if exists group_messages_delete_own on public.group_messages;
create policy group_messages_delete_own
on public.group_messages
for delete
to authenticated
using (sender_id = auth.uid());

drop policy if exists badges_select on public.badges;
create policy badges_select
on public.badges
for select
to authenticated
using (true);

drop policy if exists user_badges_select_own on public.user_badges;
create policy user_badges_select_own
on public.user_badges
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists user_badges_insert_own on public.user_badges;
create policy user_badges_insert_own
on public.user_badges
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists daily_prompts_select on public.daily_prompts;
create policy daily_prompts_select
on public.daily_prompts
for select
to authenticated
using (true);

drop policy if exists support_connections_select_own on public.support_connections;
create policy support_connections_select_own
on public.support_connections
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists support_connections_insert_own on public.support_connections;
create policy support_connections_insert_own
on public.support_connections
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists support_connections_update_own on public.support_connections;
create policy support_connections_update_own
on public.support_connections
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists support_connections_delete_own on public.support_connections;
create policy support_connections_delete_own
on public.support_connections
for delete
to authenticated
using (auth.uid() = user_id);

drop policy if exists support_messages_select_own on public.support_messages;
create policy support_messages_select_own
on public.support_messages
for select
to authenticated
using (
  exists (
    select 1
    from public.support_connections c
    where c.id = connection_id
      and c.user_id = auth.uid()
  )
);

drop policy if exists support_messages_insert_own on public.support_messages;
create policy support_messages_insert_own
on public.support_messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.support_connections c
    where c.id = connection_id
      and c.user_id = auth.uid()
  )
);

drop policy if exists dm_threads_select on public.dm_threads;
create policy dm_threads_select
on public.dm_threads
for select
to authenticated
using (auth.uid() = user_a or auth.uid() = user_b);

drop policy if exists dm_threads_insert on public.dm_threads;
create policy dm_threads_insert
on public.dm_threads
for insert
to authenticated
with check (
  (auth.uid() = user_a or auth.uid() = user_b)
  and user_a <> user_b
);

drop policy if exists dm_threads_update on public.dm_threads;
create policy dm_threads_update
on public.dm_threads
for update
to authenticated
using (auth.uid() = user_a or auth.uid() = user_b)
with check (auth.uid() = user_a or auth.uid() = user_b);

drop policy if exists dm_threads_delete on public.dm_threads;
create policy dm_threads_delete
on public.dm_threads
for delete
to authenticated
using (auth.uid() = user_a or auth.uid() = user_b);

drop policy if exists dm_messages_select on public.dm_messages;
create policy dm_messages_select
on public.dm_messages
for select
to authenticated
using (
  exists (
    select 1
    from public.dm_threads t
    where t.id = thread_id
      and (t.user_a = auth.uid() or t.user_b = auth.uid())
  )
);

drop policy if exists dm_messages_insert on public.dm_messages;
create policy dm_messages_insert
on public.dm_messages
for insert
to authenticated
with check (
  sender_id = auth.uid()
  and exists (
    select 1
    from public.dm_threads t
    where t.id = thread_id
      and (t.user_a = auth.uid() or t.user_b = auth.uid())
  )
);

drop policy if exists dm_messages_delete_own on public.dm_messages;
create policy dm_messages_delete_own
on public.dm_messages
for delete
to authenticated
using (sender_id = auth.uid());

create index if not exists idx_journal_entries_user_date
  on public.journal_entries (user_id, entry_date desc);

create index if not exists idx_community_posts_created_at
  on public.community_posts (created_at desc);

create index if not exists idx_community_posts_category_created_at
  on public.community_posts (category, created_at desc);

create index if not exists idx_community_posts_topic_created_at
  on public.community_posts (topic, created_at desc);

create index if not exists idx_community_replies_post_date
  on public.community_replies (post_id, created_at asc);

create index if not exists idx_relapse_logs_user_date
  on public.relapse_logs (user_id, relapse_date desc);

create index if not exists idx_user_habits_user
  on public.user_habits (user_id, created_at desc);

create index if not exists idx_custom_milestones_user
  on public.custom_milestones (user_id, created_at desc);

create index if not exists idx_mood_logs_user_date
  on public.mood_logs (user_id, logged_date desc);

create index if not exists idx_urge_logs_user_date
  on public.urge_logs (user_id, occurred_at desc);

create index if not exists idx_challenges_kind_active
  on public.challenges (kind, is_active, member_count desc, created_at desc);

create index if not exists idx_user_challenges_user
  on public.user_challenges (user_id, started_at desc);

create index if not exists idx_group_checkins_group_date
  on public.group_checkins (group_id, checkin_date desc);

create index if not exists idx_group_messages_group_date
  on public.group_messages (group_id, created_at asc);

create index if not exists idx_user_badges_user
  on public.user_badges (user_id, earned_at desc);

create index if not exists idx_support_connections_user
  on public.support_connections (user_id, created_at desc);

create index if not exists idx_support_messages_connection
  on public.support_messages (connection_id, created_at asc);

create index if not exists idx_dm_threads_members
  on public.dm_threads (user_a, user_b);

create index if not exists idx_dm_threads_last_message
  on public.dm_threads (last_message_at desc);

create index if not exists idx_dm_messages_thread_date
  on public.dm_messages (thread_id, created_at asc);

drop trigger if exists trg_dm_messages_bump on public.dm_messages;
create trigger trg_dm_messages_bump
after insert on public.dm_messages
for each row execute function public.bump_dm_thread();

-- Realtime (best-effort). Hosted Supabase uses publication `supabase_realtime`.
-- If you manage realtime via the dashboard, these statements are safe to keep;
-- they will no-op on errors.
alter table public.community_posts replica identity full;
alter table public.community_replies replica identity full;
alter table public.dm_threads replica identity full;
alter table public.dm_messages replica identity full;
alter table public.group_checkins replica identity full;
alter table public.group_messages replica identity full;

do $$
begin
  begin
    alter publication supabase_realtime add table public.community_posts;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.community_replies;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.dm_threads;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.dm_messages;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.group_checkins;
  exception when others then null;
  end;
  begin
    alter publication supabase_realtime add table public.group_messages;
  exception when others then null;
  end;
end $$;
