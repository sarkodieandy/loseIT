# App Store Connect Checklist (iOS)

This project is a Flutter app. Use this checklist to prepare a release build and upload it to App Store Connect.

## 1) App config (required)

- Update `pubspec.yaml` `version:` (App Store requires a new build number each upload).
- Set legal URLs in `.env`:
  - `PRIVACY_POLICY_URL`
  - `TERMS_OF_USE_URL`
- Ensure RevenueCat is configured in `.env`:
  - `REVENUECAT_IOS_API_KEY`
  - `REVENUECAT_ENTITLEMENT_ID`

## 2) iOS signing + bundle settings (Xcode)

- Open `ios/Runner.xcworkspace` in Xcode.
- Set your **Team** + **Signing** for the `Runner` target (Debug/Profile/Release).
- Confirm `Bundle Identifier` matches your App Store app (currently `com.discipline.app.discipline`).
- Capabilities:
  - In‑App Purchase (required for subscriptions)
  - HealthKit (only if you intend to ship Health features)

## 3) Local verification (before archiving)

Run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build ios --release
```

Notes:
- `--no-codesign` is only for CI/compile verification; you can’t install that build on a real device.

## 4) Archive + upload (Xcode)

- Xcode: **Product → Archive**
- Organizer: **Distribute App → App Store Connect → Upload**

## 5) App Store Connect setup

- Add **Privacy Policy URL** (must be valid and public).
- Add subscription products + pricing (match what RevenueCat Offering is using).
- Upload screenshots (recommended: include a paywall screenshot with Terms/Privacy + Restore visible).
- Fill out **App Privacy** questionnaire accurately (data collection, tracking, third‑party SDKs).
- Add review notes and test account (if any gated areas require it).

## 6) Common gotchas

- If your paywall links don’t open, check `.env` values and rebuild.
- Trial logic is server-backed via Supabase Auth `user.createdAt` (reinstall/log out won’t reset it).
- Group chat notifications are local notifications while the app is running; background/terminated push requires APNs/FCM + backend work.
