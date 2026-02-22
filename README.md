# Be Sober

A sobriety tracker with journaling, milestones, and an anonymous community feed. Built with Flutter + Supabase.

## Features
- Sobriety timer with milestones
- Money saved + time regained stats
- Journal with photos
- Voice journal + transcription (iOS)
- Anonymous community feed (Realtime)
- Community replies + DMs
- Analytics
- Challenges + custom milestones
- Support network
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
REVENUECAT_IOS_API_KEY=...
REVENUECAT_ENTITLEMENT_ID=premium
```

### 2) Supabase schema + RLS
Open the Supabase SQL editor and run `supabase/schema.sql`.

### 3) Storage buckets
Create these public buckets in Supabase Storage:
- `journal-photos`
- `motivation-photos`
- `journal-audio`

### 4) Realtime
Enable Realtime on:
- `community_posts`
- `community_replies`
- `dm_threads`
- `dm_messages`
- `support_messages`

### 5) Run
```
flutter pub get
flutter run
```

## Notes
- Anonymous sign-in is the default in onboarding.
- Email sign-in is available in onboarding.
- Info.plist includes camera + photo library + microphone + speech + health permissions.
- Premium gating uses RevenueCat (`purchases_flutter`). Configure an entitlement (default: `premium`) and an offering with packages.

## Optional
- Local notifications for milestone reminders (not enabled by default).
