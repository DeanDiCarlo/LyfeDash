# Implementation Phases

## Phase 0: Project Foundation

Goal: create a clean native iOS foundation before product features.

Verifiable goals:
- App launches to the tab shell.
- SwiftData models are defined for days, journal entries, tasks, metrics, media, and locations.
- Dashboard renders empty states without permissions or backend access.
- Apple integrations are isolated behind protocols.

## Phase 1: Journal and Tasks

Goal: ship the core habit loop locally.

Verifiable goals:
- Add, edit, and delete one-sentence journal entries.
- Create recurring task templates.
- Complete and uncomplete today tasks.
- App restart preserves local data.

## Phase 2: HealthKit Metrics

Goal: add reliable health data before higher-risk Screen Time work.

Verifiable goals:
- HealthKit permission flow is available.
- Steps and sleep aggregate into daily totals.
- Denied permissions degrade gracefully.
- HealthKit samples can be tested through mocks.

## Phase 3: Screen Time Daily Trend

Goal: add Screen Time as a constrained daily total.

Verifiable goals:
- FamilyControls authorization state is visible.
- DeviceActivity daily total adapter is isolated.
- Daily total is stored as an aggregate only.
- App remains useful without Screen Time authorization.

## Phase 4: Supabase Sync

Goal: move personal data to durable storage.

Verifiable goals:
- Supabase Auth signs a user in.
- Journal, tasks, metrics, locations, and media metadata sync.
- RLS prevents cross-user access.
- Local-first writes retry after network failure.

## Phase 5: Photos and Location Memory

Goal: create the recall substrate.

Verifiable goals:
- PhotoKit imports authorized assets.
- Compressed app copies display inside the app.
- Local Photos asset IDs support opening originals when available.
- Location events and journal/media coordinates render on a map.

## Phase 6: AI Recall Prototype

Goal: make multimodal personal recall work.

Verifiable goals:
- Uploaded media creates an AI processing job.
- Images and short videos produce captions, tags, and embeddings.
- Semantic search combines vector similarity with filters.
- Failed jobs are retryable.

## Phase 7: TestFlight Hardening

Goal: prepare a stable internal beta.

Verifiable goals:
- Fresh install onboarding handles every permission path.
- Internal TestFlight build installs on a real iPhone.
- Smoke test covers sign-in, journaling, tasks, HealthKit, media import, and recall.
- Privacy copy matches actual data upload and AI processing behavior.

