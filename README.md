# Be Sober

A sobriety tracker with journaling, milestones, and an anonymous community feed. Built with Flutter + Supabase.

## Features
- Sobriety timer with milestones
- Money saved + time regained stats
- Journal with photos
- Anonymous community feed (Realtime)
- Offline cache for profile + journal

## Tech Stack
- Flutter (Material 3)
- Supabase (Auth, Postgres, Realtime, Storage)
- Riverpod (state management)
- Hive (offline cache)

## Setup

### 1) Environment
Copy `.env.example` → `.env` and fill in values:

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

### 2) Supabase schema + RLS
Open the Supabase SQL editor and run `supabase/schema.sql`.

### 3) Storage buckets
Create these public buckets in Supabase Storage:
- `journal-photos`
- `motivation-photos`

### 4) Realtime
Enable Realtime on `community_posts` (Database → Replication).

### 5) Run
```
flutter pub get
flutter run
```

## Notes
- Anonymous sign-in is the default in onboarding.
- Email and Apple sign-in are available in onboarding.
- Info.plist includes camera + photo library permissions.

## Optional
- Local notifications for milestone reminders (not enabled by default).
