# Life Track

Life Track is an iPhone-first personal memory dashboard: journal, tasks, Apple metrics, media/location memories, and AI recall.

This repository currently contains the implementation scaffold:

- `ios/LifeTrack`: SwiftUI app source.
- `supabase/migrations`: Postgres schema, RLS, storage policy setup.
- `supabase/functions/process-memory`: Edge Function skeleton for media captioning and embedding jobs.
- `docs`: phased build goals and brand system.

## Local Development

This workspace does not include an Xcode toolchain, so the iOS app cannot be built here. On macOS:

1. Create a new iOS SwiftUI app target in Xcode named `LifeTrack`.
2. Add the files under `ios/LifeTrack` to the app target.
3. Enable capabilities as phases require them:
   - HealthKit
   - Family Controls
   - App Groups if needed for DeviceActivity extensions later
   - Background Modes: location updates
   - Photo Library usage descriptions in `Info.plist`
4. Add Supabase Swift when Phase 4 begins.

## Architecture Defaults

- Native SwiftUI iPhone app.
- SwiftData local-first persistence.
- Supabase Auth, Postgres, Storage, Edge Functions, and pgvector.
- Daily Apple-derived aggregates only are uploaded.
- Compressed app media copies are uploaded; originals remain in Photos/iCloud.
- AI provider abstraction starts provider-agnostic, with Gemini expected as the first backend implementation.

