# Xcode Setup

## Preferred setup

From macOS:

```sh
make setup
```

This verifies Xcode, selects `/Applications/Xcode.app`, installs XcodeGen through Homebrew when needed, and generates the project.

## Manual setup

Use XcodeGen from the repository root:

```sh
xcodegen generate
open LifeTrack.xcodeproj
```

If XcodeGen is not installed:

```sh
brew install xcodegen
```

## Build and test

```sh
make build
make test
```

The default destination is `platform=iOS Simulator,name=iPhone 16`. Change `DESTINATION` in the root `Makefile` if your installed simulator name differs.

## Capabilities

After opening the project in Xcode, confirm these capabilities on the `LifeTrack` app target:

- HealthKit
- Family Controls
- Background Modes: Location updates

Screen Time APIs may require Apple Developer Program entitlement approval before they work in TestFlight or App Store distribution.

## Required packages

The scaffold is dependency-free for Phase 0 and Phase 1. Add packages only when a phase needs them:

- Phase 4: Supabase Swift client.
- Phase 6: any backend-only AI SDKs should stay out of the iOS target unless there is a clear on-device use case.

## Source layout

The Xcode target reads from `apps/ios/LifeTrack`.

- `App`: app entrypoint and root navigation.
- `Core`: shared models, domain helpers, design system, and service protocols/adapters.
- `Features`: screen modules grouped by product area.
- `Resources`: app plist, entitlements, and future assets.
