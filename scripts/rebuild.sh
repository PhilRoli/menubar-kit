#!/bin/bash
set -euo pipefail
KIT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="${1:?Usage: rebuild.sh <AppName>}"
APP="/Applications/$APP_NAME.app"

"$KIT/package-app.sh" "$APP_NAME" 0.0.0-dev

echo "Stopping running instance..."
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

echo "Installing..."
rm -rf "$APP"
cp -R "$(pwd)/.build/package/$APP_NAME.app" "$APP"

echo "Re-signing..."
codesign --remove-signature "$APP"
codesign -s - "$APP"

echo "Launching..."
open "$APP"
echo "Done."
