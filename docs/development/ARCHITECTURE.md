# Architecture

## Repository Boundaries

- `apps/ios`: native iPhone app and iOS tests.
- `backend/supabase`: database migrations and Edge Functions.
- `docs/development`: engineering setup and phase plans.
- `docs/product`: brand, UX, and product direction.

## iOS Boundaries

- `App`: process entrypoint, dependency injection, and root navigation only.
- `Core/Models`: SwiftData entities and shared value enums.
- `Core/Domain`: pure domain logic that should be easy to unit test.
- `Core/Services`: framework and backend integration protocols/adapters.
- `Core/Design`: shared visual tokens and reusable design primitives.
- `Features`: user-facing screens grouped by product capability.

Keep Apple frameworks and backend clients behind protocols in `Core/Services`. Feature views should depend on protocols or environment services, not concrete HealthKit, Screen Time, PhotoKit, Location, or Supabase clients.

## Backend Boundaries

Supabase is kept under `backend/supabase` so backend code does not blend into app source.

- `migrations`: schema, RLS, indexes, and SQL functions.
- `functions`: Edge Functions for AI/media processing and future sync helpers.

Backend code should treat Apple-derived metrics as daily aggregates. Detailed Screen Time app/domain data should not be uploaded.
