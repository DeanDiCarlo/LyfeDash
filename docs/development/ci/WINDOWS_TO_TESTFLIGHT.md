# Windows to TestFlight Workflow

You can write the app from Windows/WSL, but an iOS app still needs a macOS build machine somewhere. This repository uses GitHub Actions macOS runners as that machine.

## What Works From Windows

- Edit Swift, SQL, docs, and workflows.
- Push to GitHub.
- Run unsigned iOS simulator builds through `.github/workflows/ios-ci.yml`.
- Trigger a signed TestFlight upload through `.github/workflows/testflight.yml` after Apple signing secrets are configured.

## What Still Requires Apple Infrastructure

- Apple Developer Program membership.
- App Store Connect app record.
- Bundle ID and App ID for `com.deanomeano.lifetrack`.
- Distribution certificate and provisioning profile.
- Family Controls entitlement approval before Screen Time distribution can be trusted.

## GitHub Secrets for TestFlight

Add these repository secrets before running the manual `TestFlight` workflow:

- `APPLE_TEAM_ID`: Apple Developer team ID.
- `BUILD_CERTIFICATE_BASE64`: base64-encoded `.p12` Apple Distribution certificate.
- `P12_PASSWORD`: password for the `.p12` certificate.
- `BUILD_PROVISION_PROFILE_BASE64`: base64-encoded App Store provisioning profile.
- `KEYCHAIN_PASSWORD`: throwaway CI keychain password.
- `ASC_KEY_ID`: App Store Connect API key ID.
- `ASC_ISSUER_ID`: App Store Connect issuer ID.
- `ASC_PRIVATE_KEY`: full `.p8` private key contents.

## Recommended Next Move

1. Keep coding from Windows/WSL.
2. Use `iOS CI` on GitHub Actions as the first compiler gate.
3. Fix compile errors surfaced by CI.
4. Once CI passes, create the Apple Developer/App Store Connect signing assets.
5. Run the manual `TestFlight` workflow.

For this app specifically, do not make Screen Time the first TestFlight blocker. Ship journal, tasks, HealthKit, photo import, and backend sync first; keep Screen Time behind a feature flag until the entitlement path is proven.
