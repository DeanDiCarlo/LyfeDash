#!/usr/bin/env bash
set -euo pipefail

ipa_path="${1:-}"
if [[ -z "$ipa_path" || ! -f "$ipa_path" ]]; then
  echo "Usage: $0 path/to/App.ipa"
  exit 1
fi

required_vars=(ASC_KEY_ID ASC_ISSUER_ID ASC_PRIVATE_KEY)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "$var is required."
    exit 1
  fi
done

private_keys_dir="$RUNNER_TEMP/private_keys"
mkdir -p "$private_keys_dir"
key_path="$private_keys_dir/AuthKey_${ASC_KEY_ID}.p8"
printf '%s' "$ASC_PRIVATE_KEY" > "$key_path"

xcrun altool \
  --upload-app \
  --type ios \
  --file "$ipa_path" \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID"
