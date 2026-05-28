#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This setup script must run on macOS because Xcode is macOS-only."
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode command line tools..."
  xcode-select --install
  echo "Rerun this script after the command line tools finish installing."
  exit 0
fi

if [[ ! -d "/Applications/Xcode.app" ]]; then
  echo "Xcode.app was not found in /Applications."
  echo "Install Xcode from the Mac App Store or Apple Developer Downloads, then rerun this script."
  exit 1
fi

sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept >/dev/null || true
xcodebuild -runFirstLaunch

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Install it from https://brew.sh, then rerun this script."
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  brew install xcodegen
fi

xcodegen generate

echo "macOS setup complete. Open LifeTrack.xcodeproj or run make test."
