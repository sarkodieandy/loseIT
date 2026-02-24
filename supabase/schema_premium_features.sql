-- Extended schema for Premium Features (2-8)
-- Features 2-8 database tables and RLS policies

-- ============================================================================
-- FEATURE 2: ACCOUNTABILITY & SOCIAL FEATURES
-- ============================================================================

create table if not exists public.accountability_partners (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  partner_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending', -- 'pending', 'accepted', 'rejected'
  requested_at timestamptz not null default now(),
  accepted_at timestamptz null,
  created_at timestamptz not null default now(),
  unique(user_id, partner_id)
);

create table if not exists public.accountability_weekly_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  partner_id uuid null references public.profiles (id) on delete set null,
  week_start_date date not null,
  journal_entries_count integer not null default 0,
  community_posts_count integer not null default 0,
  days_sober integer not null default 0,
  streak_maintained boolean not null default true,
  notes text null,
  created_at timestamptz not null default now(),
  unique(user_id, week_start_date)
);

create table if not exists public.group_challenges (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text null,
  duration_days integer not null default 7, -- 7, 30, or 90
  is_anonymous boolean not null default true,
  visibility text not null default 'public', -- 'public' or 'closed'
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  is_active boolean not null default true
);

create table if not exists public.group_challenge_members (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.group_challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  progress_int integer not null default 0,
  joined_at timestamptz not null default now(),
  completed_at timestamptz null,
  unique(challenge_id, user_id)
);

create table if not exists public.emergency_sos_contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  contact_name text not null,
  contact_phone text not null,
  contact_email text null,
  is_primary boolean not null default false,
  is_active boolean not null default true,
  last_contacted_at timestamptz null,
  created_at timestamptz not null default now()
);

create table if not exists public.emergency_activations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  sos_contact_id uuid null references public.emergency_sos_contacts (id) on delete set null,
  status text not null default 'active', -- 'active', 'resolved', 'cancelled'
  activated_at timestamptz not null default now(),
  resolved_at timestamptz null,
  technique_used text null,
  outcome text null
);

-- ============================================================================
-- FEATURE 3: GUIDED JOURNALING & THERAPY INTEGRATION
-- ============================================================================

create table if not exists public.journal_prompts_by_mood (
  id uuid primary key default gen_random_uuid(),
  mood text not null, -- 'happy', 'sad', 'anxious', 'angry', 'stressed', 'craving'
  prompt_text text not null,
  prompt_category text not null, -- 'reflection', 'coping', 'insight'
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.craving_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  habit_id uuid null references public.user_habits (id) on delete set null,
  intensity integer not null default 5, -- 1-10 scale
  trigger text null,
  coping_strategy_used text null,
  was_successful boolean null,
  duration_minutes integer null,
  notes text null,
  logged_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.coping_strategies (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  category text not null, -- 'breathing', 'grounding', 'distraction', 'movement'
  duration_minutes integer null,
  instructions text null,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.recovery_workbook_modules (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  content text not null,
  module_type text not null, -- 'cbt', 'mindfulness', 'motivation', 'relapse_prevention'
  order_index integer not null,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.user_workbook_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  module_id uuid not null references public.recovery_workbook_modules (id) on delete cascade,
  completed boolean not null default false,
  completed_at timestamptz null,
  notes text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, module_id)
);

create table if not exists public.therapy_exports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  exported_data jsonb not null, -- journal entries, moods, cravings exported
  export_type text not null, -- 'journal', 'full_summary', 'craving_analysis'
  export_date_range text null,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- FEATURE 4: ADVANCED MILESTONE BUILDING
-- ============================================================================

create table if not exists public.milestone_templates (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  days_threshold integer null, -- e.g., 30 days sober
  target_value numeric null,
  unit text null,
  badge_icon_url text null,
  reward_points integer not null default 10,
  is_premium boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.user_milestone_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  template_id uuid not null references public.milestone_templates (id) on delete cascade,
  current_value numeric null,
  completed boolean not null default false,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  unique(user_id, template_id)
);

create table if not exists public.reward_marketplace (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null,
  points_required integer not null,
  category text not null, -- 'physical', 'wellness', 'entertainment', 'charity'
  external_link text null,
  image_url text null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.user_reward_redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  reward_id uuid not null references public.reward_marketplace (id) on delete cascade,
  points_spent integer not null,
  redeemed_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.family_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  family_member_name text not null,
  achievement_title text not null,
  description text null,
  celebration_date timestamptz not null,
  is_shared boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.progress_walls (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  milestones_reached integer not null default 0,
  total_milestones integer not null default 0,
  progress_percentage numeric not null default 0,
  is_shareable boolean not null default true,
  share_token text unique null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- FEATURE 5: COMMUNITY MODERATION & SAFETY
-- ============================================================================

create table if not exists public.community_user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  badge_type text not null, -- 'verified_sponsor', 'verified_counselor', 'trusted_voice'
  verified_by uuid null references public.profiles (id) on delete set null,
  verified_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, badge_type)
);

create table if not exists public.notification_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  reply_notifications boolean not null default true,
  message_notifications boolean not null default true,
  challenge_updates boolean not null default true,
  milestone_celebrations boolean not null default true,
  community_digest boolean not null default false,
  quiet_hours_start time null, -- e.g., 22:00
  quiet_hours_end time null,   -- e.g., 08:00
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.notification_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  notification_type text not null, -- 'reply', 'message', 'challenge', 'milestone'
  triggered_by_user uuid null references public.profiles (id) on delete set null,
  related_id uuid null,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  read_at timestamptz null,
  created_at timestamptz not null default now()
);

create table if not exists public.private_groups (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  is_private boolean not null default true,
  invite_only boolean not null default true,
  invite_code text unique null,
  max_members integer null,
  created_at timestamptz not null default now(),
  unique(challenge_id)
);

create table if not exists public.group_invites (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.private_groups (id) on delete cascade,
  invited_user_id uuid not null references public.profiles (id) on delete cascade,
  invited_by uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending', -- 'pending', 'accepted', 'declined'
  created_at timestamptz not null default now(),
  unique(group_id, invited_user_id)
);

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  blocked_user_id uuid not null references public.profiles (id) on delete cascade,
  reason text null,
  blocked_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique(user_id, blocked_user_id)
);

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reported_by uuid not null references public.profiles (id) on delete cascade,
  post_id bigint null references public.community_posts (id) on delete cascade,
  comment_id uuid null references public.community_replies (id) on delete cascade,
  reason text not null, -- 'spam', 'offensive', 'triggering', 'scam'
  description text null,
  status text not null default 'pending', -- 'pending', 'reviewed', 'resolved'
  created_at timestamptz not null default now()
);

-- ============================================================================
-- FEATURE 6: FOCUS & PROTECTION TOOLS
-- ============================================================================

create table if not exists public.focus_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  session_name text not null,
  duration_minutes integer not null,
  points_earned integer not null default 0,
  started_at timestamptz not null,
  ended_at timestamptz null,
  completed boolean not null default false,
  notes text null,
  created_at timestamptz not null default now()
);

create table if not exists public.morning_evening_routines (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  routine_type text not null, -- 'morning' or 'evening'
  routine_name text not null,
  description text null,
  scheduled_time time not null, -- e.g., '06:00:00'
  is_active boolean not null default true,
  reminder_enabled boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.routine_checkouts (
  id uuid primary key default gen_random_uuid(),
  routine_id uuid not null references public.morning_evening_routines (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  completed boolean not null default false,
  completed_at timestamptz null,
  mood_before text null,
  mood_after text null,
  checkout_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.sobriety_affirmations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  affirmation_text text not null,
  category text null, -- 'motivation', 'strength', 'healing'
  is_custom boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.blocked_apps (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  app_name text not null,
  app_package_id text not null,
  reason text null,
  is_active boolean not null default true,
  triggered_alternative text null, -- e.g., offer focus session instead
  created_at timestamptz not null default now(),
  unique(user_id, app_package_id)
);

-- ============================================================================
-- FEATURE 7: FINANCIAL TRACKING
-- ============================================================================

create table if not exists public.financial_goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  goal_name text not null,
  target_amount numeric not null,
  current_amount numeric not null default 0,
  reason text null,
  target_date date null,
  is_completed boolean not null default false,
  completed_at timestamptz null,
  created_at timestamptz not null default now()
);

create table if not exists public.spending_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category_name text not null,
  color_hex text null,
  daily_spend numeric null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.spending_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid null references public.spending_categories (id) on delete set null,
  amount numeric not null,
  description text null,
  logged_date date not null default current_date,
  created_at timestamptz not null default now()
);

create table if not exists public.charity_donations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  organization_name text not null,
  organization_url text null,
  amount_donated numeric not null,
  donation_date date not null default current_date,
  is_recurring boolean not null default false,
  recurring_frequency text null, -- 'weekly', 'monthly', 'yearly'
  created_at timestamptz not null default now()
);

create table if not exists public.financial_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  period_start_date date not null,
  period_end_date date not null,
  total_saved numeric not null,
  total_spent numeric not null,
  goal_progress_percentage numeric null,
  chart_data jsonb null, -- JSON breakdown by category
  created_at timestamptz not null default now()
);

-- ============================================================================
-- FEATURE 8: DATA EXPORT & CONTINUITY
-- ============================================================================

create table if not exists public.exported_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  report_type text not null, -- 'therapy_summary', 'progress_report', 'full_export'
  file_format text not null default 'pdf', -- 'pdf', 'json', 'csv'
  file_url text not null,
  file_size_bytes integer null,
  include_journals boolean not null default true,
  include_analytics boolean not null default true,
  include_medical_notes boolean not null default false,
  exported_at timestamptz not null default now(),
  is_available boolean not null default true,
  expires_at timestamptz null,
  created_at timestamptz not null default now()
);

create table if not exists public.cloud_backups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  backup_type text not null default 'auto', -- 'auto', 'manual'
  data_snapshot jsonb not null,
  backup_size_bytes integer null,
  encryption_key_hash text null,
  backed_up_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.backup_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  backup_frequency text not null default 'daily', -- 'daily', 'weekly'
  time_of_day time null,
  is_enabled boolean not null default true,
  last_backup_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.calendar_sync_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  sync_enabled boolean not null default false,
  calendar_provider text null, -- 'google', 'apple', 'outlook'
  sync_milestones boolean not null default true,
  sync_challenges boolean not null default true,
  sync_reminders boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.health_kit_integrations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  integration_enabled boolean not null default false,
  framework text null, -- 'healthkit', 'google_fit'
  synced_metrics text[] null, -- e.g., ['steps', 'heart_rate', 'sleep']
  last_sync_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

-- ============================================================================
-- INDEXES for performance
-- ============================================================================

create index if not exists idx_accountability_partners_user
  on public.accountability_partners (user_id, status);

create index if not exists idx_accountability_reports_user_week
  on public.accountability_weekly_reports (user_id, week_start_date desc);

create index if not exists idx_group_challenges_active
  on public.group_challenges (is_active, created_at desc);

create index if not exists idx_craving_logs_user_date
  on public.craving_logs (user_id, logged_at desc);

create index if not exists idx_user_workbook_progress_user
  on public.user_workbook_progress (user_id, completed);

create index if not exists idx_milestone_templates_premium
  on public.milestone_templates (is_premium, created_at desc);

create index if not exists idx_community_user_badges_user
  on public.community_user_badges (user_id, badge_type);

create index if not exists idx_notification_history_user_date
  on public.notification_history (user_id, created_at desc);

create index if not exists idx_focus_sessions_user_date
  on public.focus_sessions (user_id, started_at desc);

create index if not exists idx_financial_goals_user
  on public.financial_goals (user_id, created_at desc);

create index if not exists idx_spending_logs_user_date
  on public.spending_logs (user_id, logged_date desc);

create index if not exists idx_exported_reports_user_date
  on public.exported_reports (user_id, exported_at desc);

create index if not exists idx_cloud_backups_user_date
  on public.cloud_backups (user_id, backed_up_at desc);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

alter table public.accountability_partners enable row level security;
alter table public.accountability_weekly_reports enable row level security;
alter table public.group_challenges enable row level security;
alter table public.group_challenge_members enable row level security;
alter table public.emergency_sos_contacts enable row level security;
alter table public.emergency_activations enable row level security;
alter table public.journal_prompts_by_mood enable row level security;
alter table public.craving_logs enable row level security;
alter table public.coping_strategies enable row level security;
alter table public.recovery_workbook_modules enable row level security;
alter table public.user_workbook_progress enable row level security;
alter table public.therapy_exports enable row level security;
alter table public.milestone_templates enable row level security;
alter table public.user_milestone_templates enable row level security;
alter table public.reward_marketplace enable row level security;
alter table public.user_reward_redemptions enable row level security;
alter table public.family_achievements enable row level security;
alter table public.progress_walls enable row level security;
alter table public.community_user_badges enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.notification_history enable row level security;
alter table public.private_groups enable row level security;
alter table public.group_invites enable row level security;
alter table public.blocked_users enable row level security;
alter table public.content_reports enable row level security;
alter table public.focus_sessions enable row level security;
alter table public.morning_evening_routines enable row level security;
alter table public.routine_checkouts enable row level security;
alter table public.sobriety_affirmations enable row level security;
alter table public.blocked_apps enable row level security;
alter table public.financial_goals enable row level security;
alter table public.spending_categories enable row level security;
alter table public.spending_logs enable row level security;
alter table public.charity_donations enable row level security;
alter table public.financial_insights enable row level security;
alter table public.exported_reports enable row level security;
alter table public.cloud_backups enable row level security;
alter table public.backup_schedules enable row level security;
alter table public.calendar_sync_settings enable row level security;
alter table public.health_kit_integrations enable row level security;

-- Accountability Partners RLS
drop policy if exists accountability_partners_select_own on public.accountability_partners;
create policy accountability_partners_select_own
  on public.accountability_partners for select to authenticated
  using (auth.uid() = user_id or auth.uid() = partner_id);

drop policy if exists accountability_partners_insert_own on public.accountability_partners;
create policy accountability_partners_insert_own
  on public.accountability_partners for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists accountability_partners_update_own on public.accountability_partners;
create policy accountability_partners_update_own
  on public.accountability_partners for update to authenticated
  using (auth.uid() = user_id or auth.uid() = partner_id)
  with check (auth.uid() = user_id or auth.uid() = partner_id);

-- Weekly Reports RLS
drop policy if exists accountability_reports_select_own on public.accountability_weekly_reports;
create policy accountability_reports_select_own
  on public.accountability_weekly_reports for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists accountability_reports_insert_own on public.accountability_weekly_reports;
create policy accountability_reports_insert_own
  on public.accountability_weekly_reports for insert to authenticated
  with check (auth.uid() = user_id);

-- Group Challenges RLS
drop policy if exists group_challenges_select on public.group_challenges;
create policy group_challenges_select
  on public.group_challenges for select to authenticated
  using (true);

drop policy if exists group_challenges_insert_own on public.group_challenges;
create policy group_challenges_insert_own
  on public.group_challenges for insert to authenticated
  with check (auth.uid() = created_by);

-- Group Challenge Members RLS
drop policy if exists group_challenge_members_select_own on public.group_challenge_members;
create policy group_challenge_members_select_own
  on public.group_challenge_members for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists group_challenge_members_insert_own on public.group_challenge_members;
create policy group_challenge_members_insert_own
  on public.group_challenge_members for insert to authenticated
  with check (auth.uid() = user_id);

-- Emergency SOS Contacts RLS
drop policy if exists emergency_sos_select_own on public.emergency_sos_contacts;
create policy emergency_sos_select_own
  on public.emergency_sos_contacts for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists emergency_sos_insert_own on public.emergency_sos_contacts;
create policy emergency_sos_insert_own
  on public.emergency_sos_contacts for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists emergency_sos_update_own on public.emergency_sos_contacts;
create policy emergency_sos_update_own
  on public.emergency_sos_contacts for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Craving Logs RLS
drop policy if exists craving_logs_select_own on public.craving_logs;
create policy craving_logs_select_own
  on public.craving_logs for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists craving_logs_insert_own on public.craving_logs;
create policy craving_logs_insert_own
  on public.craving_logs for insert to authenticated
  with check (auth.uid() = user_id);

-- Focus Sessions RLS
drop policy if exists focus_sessions_select_own on public.focus_sessions;
create policy focus_sessions_select_own
  on public.focus_sessions for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists focus_sessions_insert_own on public.focus_sessions;
create policy focus_sessions_insert_own
  on public.focus_sessions for insert to authenticated
  with check (auth.uid() = user_id);

-- Financial Goals RLS
drop policy if exists financial_goals_select_own on public.financial_goals;
create policy financial_goals_select_own
  on public.financial_goals for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists financial_goals_insert_own on public.financial_goals;
create policy financial_goals_insert_own
  on public.financial_goals for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists financial_goals_update_own on public.financial_goals;
create policy financial_goals_update_own
  on public.financial_goals for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Spending Logs RLS
drop policy if exists spending_logs_select_own on public.spending_logs;
create policy spending_logs_select_own
  on public.spending_logs for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists spending_logs_insert_own on public.spending_logs;
create policy spending_logs_insert_own
  on public.spending_logs for insert to authenticated
  with check (auth.uid() = user_id);

-- Notification History RLS
drop policy if exists notification_history_select_own on public.notification_history;
create policy notification_history_select_own
  on public.notification_history for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists notification_history_insert_own on public.notification_history;
create policy notification_history_insert_own
  on public.notification_history for insert to authenticated
  with check (auth.uid() = user_id);

-- Exported Reports RLS
drop policy if exists exported_reports_select_own on public.exported_reports;
create policy exported_reports_select_own
  on public.exported_reports for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists exported_reports_insert_own on public.exported_reports;
create policy exported_reports_insert_own
  on public.exported_reports for insert to authenticated
  with check (auth.uid() = user_id);

-- Cloud Backups RLS
drop policy if exists cloud_backups_select_own on public.cloud_backups;
create policy cloud_backups_select_own
  on public.cloud_backups for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists cloud_backups_insert_own on public.cloud_backups;
create policy cloud_backups_insert_own
  on public.cloud_backups for insert to authenticated
  with check (auth.uid() = user_id);

-- Coping Strategies & Recovery Modules
drop policy if exists coping_strategies_select on public.coping_strategies;
create policy coping_strategies_select
  on public.coping_strategies for select to authenticated
  using (true);

drop policy if exists recovery_modules_select on public.recovery_workbook_modules;
create policy recovery_modules_select
  on public.recovery_workbook_modules for select to authenticated
  using (true);

-- User Workbook Progress RLS
drop policy if exists user_workbook_progress_select_own on public.user_workbook_progress;
create policy user_workbook_progress_select_own
  on public.user_workbook_progress for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists user_workbook_progress_insert_own on public.user_workbook_progress;
create policy user_workbook_progress_insert_own
  on public.user_workbook_progress for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists user_workbook_progress_update_own on public.user_workbook_progress;
create policy user_workbook_progress_update_own
  on public.user_workbook_progress for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Morning/Evening Routines RLS
drop policy if exists routines_select_own on public.morning_evening_routines;
create policy routines_select_own
  on public.morning_evening_routines for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists routines_insert_own on public.morning_evening_routines;
create policy routines_insert_own
  on public.morning_evening_routines for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists routines_update_own on public.morning_evening_routines;
create policy routines_update_own
  on public.morning_evening_routines for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Sobriety Affirmations RLS
drop policy if exists affirmations_select_own on public.sobriety_affirmations;
create policy affirmations_select_own
  on public.sobriety_affirmations for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists affirmations_insert_own on public.sobriety_affirmations;
create policy affirmations_insert_own
  on public.sobriety_affirmations for insert to authenticated
  with check (auth.uid() = user_id);

-- Family Achievements RLS
drop policy if exists family_achievements_select_own on public.family_achievements;
create policy family_achievements_select_own
  on public.family_achievements for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists family_achievements_insert_own on public.family_achievements;
create policy family_achievements_insert_own
  on public.family_achievements for insert to authenticated
  with check (auth.uid() = user_id);

-- Progress Walls RLS
drop policy if exists progress_walls_select_own on public.progress_walls;
create policy progress_walls_select_own
  on public.progress_walls for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists progress_walls_insert_own on public.progress_walls;
create policy progress_walls_insert_own
  on public.progress_walls for insert to authenticated
  with check (auth.uid() = user_id);

-- Community User Badges RLS
drop policy if exists community_user_badges_select on public.community_user_badges;
create policy community_user_badges_select
  on public.community_user_badges for select to authenticated
  using (true);

-- Notification Preferences RLS
drop policy if exists notification_preferences_select_own on public.notification_preferences;
create policy notification_preferences_select_own
  on public.notification_preferences for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists notification_preferences_insert_own on public.notification_preferences;
create policy notification_preferences_insert_own
  on public.notification_preferences for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists notification_preferences_update_own on public.notification_preferences;
create policy notification_preferences_update_own
  on public.notification_preferences for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Additional table policies follow similar pattern...
drop policy if exists content_reports_insert_own on public.content_reports;
create policy content_reports_insert_own
  on public.content_reports for insert to authenticated
  with check (auth.uid() = reported_by);

drop policy if exists content_reports_select_admin on public.content_reports;
create policy content_reports_select_admin
  on public.content_reports for select to authenticated
  using (true); -- In production, restrict to admins only

drop policy if exists blocked_users_select_own on public.blocked_users;
create policy blocked_users_select_own
  on public.blocked_users for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists blocked_users_insert_own on public.blocked_users;
create policy blocked_users_insert_own
  on public.blocked_users for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists reward_marketplace_select on public.reward_marketplace;
create policy reward_marketplace_select
  on public.reward_marketplace for select to authenticated
  using (true);

drop policy if exists user_reward_redemptions_insert_own on public.user_reward_redemptions;
create policy user_reward_redemptions_insert_own
  on public.user_reward_redemptions for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists user_reward_redemptions_select_own on public.user_reward_redemptions;
create policy user_reward_redemptions_select_own
  on public.user_reward_redemptions for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists charity_donations_select_own on public.charity_donations;
create policy charity_donations_select_own
  on public.charity_donations for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists charity_donations_insert_own on public.charity_donations;
create policy charity_donations_insert_own
  on public.charity_donations for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists financial_insights_select_own on public.financial_insights;
create policy financial_insights_select_own
  on public.financial_insights for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists backup_schedules_select_own on public.backup_schedules;
create policy backup_schedules_select_own
  on public.backup_schedules for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists backup_schedules_insert_own on public.backup_schedules;
create policy backup_schedules_insert_own
  on public.backup_schedules for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists backup_schedules_update_own on public.backup_schedules;
create policy backup_schedules_update_own
  on public.backup_schedules for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists calendar_sync_settings_select_own on public.calendar_sync_settings;
create policy calendar_sync_settings_select_own
  on public.calendar_sync_settings for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists calendar_sync_settings_insert_own on public.calendar_sync_settings;
create policy calendar_sync_settings_insert_own
  on public.calendar_sync_settings for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists calendar_sync_settings_update_own on public.calendar_sync_settings;
create policy calendar_sync_settings_update_own
  on public.calendar_sync_settings for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists health_kit_integrations_select_own on public.health_kit_integrations;
create policy health_kit_integrations_select_own
  on public.health_kit_integrations for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists health_kit_integrations_insert_own on public.health_kit_integrations;
create policy health_kit_integrations_insert_own
  on public.health_kit_integrations for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists health_kit_integrations_update_own on public.health_kit_integrations;
create policy health_kit_integrations_update_own
  on public.health_kit_integrations for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Journal Prompts by Mood select
drop policy if exists journal_prompts_by_mood_select on public.journal_prompts_by_mood;
create policy journal_prompts_by_mood_select
  on public.journal_prompts_by_mood for select to authenticated
  using (true);

-- Therapy Exports RLS
drop policy if exists therapy_exports_select_own on public.therapy_exports;
create policy therapy_exports_select_own
  on public.therapy_exports for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists therapy_exports_insert_own on public.therapy_exports;
create policy therapy_exports_insert_own
  on public.therapy_exports for insert to authenticated
  with check (auth.uid() = user_id);

-- Milestone Templates RLS
drop policy if exists milestone_templates_select on public.milestone_templates;
create policy milestone_templates_select
  on public.milestone_templates for select to authenticated
  using (true);

-- User Milestone Templates RLS
drop policy if exists user_milestone_templates_select_own on public.user_milestone_templates;
create policy user_milestone_templates_select_own
  on public.user_milestone_templates for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists user_milestone_templates_insert_own on public.user_milestone_templates;
create policy user_milestone_templates_insert_own
  on public.user_milestone_templates for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists user_milestone_templates_update_own on public.user_milestone_templates;
create policy user_milestone_templates_update_own
  on public.user_milestone_templates for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
