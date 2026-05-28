# Life Track

Life Track is an iPhone-first personal memory dashboard: journal, tasks, Apple metrics, media/location memories, and AI recall.

This repository currently contains the implementation scaffold:

- `apps/ios/LifeTrack`: SwiftUI app source.
- `apps/ios/LifeTrackTests`: iOS unit tests.
- `backend/supabase/migrations`: Postgres schema, RLS, storage policy setup.
- `backend/supabase/functions/process-memory`: Edge Function skeleton for media captioning and embedding jobs.
- `docs/development`: build phases and setup notes.
- `docs/product`: brand and product direction.

## Local Development

This workspace does not include an Xcode toolchain, so the iOS app cannot be built here. On macOS:

1. Install Xcode from the Mac App Store or Apple Developer Downloads.
2. Run `make setup`.
3. Open `LifeTrack.xcodeproj`.
4. Enable capabilities as phases require them:
   - HealthKit
   - Family Controls
   - App Groups if needed for DeviceActivity extensions later
   - Background Modes: location updates
   - Photo Library usage descriptions in `Info.plist`
5. Add Supabase Swift when Phase 4 begins.

If using XcodeGen, follow [docs/development/XCODE_SETUP.md](docs/development/XCODE_SETUP.md).

## Architecture Defaults

- Native SwiftUI iPhone app.
- SwiftData local-first persistence.
- Supabase Auth, Postgres, Storage, Edge Functions, and pgvector.
- Daily Apple-derived aggregates only are uploaded.
- Compressed app media copies are uploaded; originals remain in Photos/iCloud.
- AI provider abstraction starts provider-agnostic, with Gemini expected as the first backend implementation.

## Repository Layout

```text
apps/
  ios/
    LifeTrack/
      App/          # App entrypoint and root navigation
      Core/         # Shared models, services, design tokens, domain logic
      Features/     # Screen-level feature modules
      Resources/    # Info.plist, entitlements, assets later
    LifeTrackTests/
backend/
  supabase/
    migrations/
    functions/
docs/
  development/
  product/
```
