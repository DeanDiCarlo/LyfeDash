#!/usr/bin/env bash
set -euo pipefail

required_vars=(SUPABASE_URL SUPABASE_ANON_KEY)
for var in "${required_vars[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    if [[ "${REQUIRE_SUPABASE_CONFIG:-false}" != "true" ]]; then
      echo "$var is not set. Skipping SupabaseSecrets.plist generation."
      exit 0
    fi

    echo "$var is required."
    exit 1
  fi
done

secrets_path="apps/ios/LifeTrack/Resources/SupabaseSecrets.plist"

cat > "$secrets_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>SUPABASE_URL</key>
  <string>${SUPABASE_URL}</string>
  <key>SUPABASE_ANON_KEY</key>
  <string>${SUPABASE_ANON_KEY}</string>
</dict>
</plist>
PLIST

echo "Wrote $secrets_path"
