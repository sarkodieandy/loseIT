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

create table if not exists public.community_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  anonymous_name text not null,
  content text not null,
  likes integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.relapse_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  relapse_date timestamptz not null default now(),
  note text null,
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

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.journal_entries enable row level security;
alter table public.community_posts enable row level security;
alter table public.relapse_logs enable row level security;

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

create index if not exists idx_journal_entries_user_date
  on public.journal_entries (user_id, entry_date desc);

create index if not exists idx_community_posts_created_at
  on public.community_posts (created_at desc);

create index if not exists idx_relapse_logs_user_date
  on public.relapse_logs (user_id, relapse_date desc);
