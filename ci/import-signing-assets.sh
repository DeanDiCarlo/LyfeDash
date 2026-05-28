#!/usr/bin/env bash
set -euo pipefail

required_vars=(
  BUILD_CERTIFICATE_BASE64
  P12_PASSWORD
  BUILD_PROVISION_PROFILE_BASE64
  KEYCHAIN_PASSWORD
)

for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "$var is required."
    exit 1
  fi
done

certificate_path="$RUNNER_TEMP/build_certificate.p12"
profile_path="$RUNNER_TEMP/build_profile.mobileprovision"
keychain_path="$RUNNER_TEMP/app-signing.keychain-db"

echo "$BUILD_CERTIFICATE_BASE64" | base64 --decode > "$certificate_path"
echo "$BUILD_PROVISION_PROFILE_BASE64" | base64 --decode > "$profile_path"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$keychain_path"
security set-keychain-settings -lut 21600 "$keychain_path"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$keychain_path"
security import "$certificate_path" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$keychain_path"
security list-keychain -d user -s "$keychain_path"

mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$profile_path" "$HOME/Library/MobileDevice/Provisioning Profiles/"
