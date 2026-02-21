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
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

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
  add column if not exists habit_id uuid null references public.user_habits (id) on delete set null;

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  anonymous_name text not null,
  content text not null,
  likes integer not null default 0,
  created_at timestamptz not null default now()
);

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

  if post_id_type is null or post_id_type = 'uuid' then
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
  else
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
  end if;
end $$;

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

create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text null,
  duration_days integer null,
  badge_image_url text null,
  is_active boolean not null default true
);

create table if not exists public.user_challenges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  progress integer not null default 0,
  completed boolean not null default false,
  started_at timestamptz not null default now(),
  completed_at timestamptz null
);

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
alter table public.challenges enable row level security;
alter table public.user_challenges enable row level security;
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

drop policy if exists challenges_select on public.challenges;
create policy challenges_select
on public.challenges
for select
to authenticated
using (true);

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

create index if not exists idx_user_challenges_user
  on public.user_challenges (user_id, started_at desc);

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
