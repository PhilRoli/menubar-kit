#!/bin/bash
set -euo pipefail

APP_NAME="${1:?Usage: package-app.sh <AppName> <version>}"
VERSION="${2:?Usage: package-app.sh <AppName> <version>}"
BUILD_VERSION="${VERSION%%-*}"   # CFBundleVersion must be numeric, so drop any -suffix
REPO="$(pwd)"
[ -f "$REPO/Package.swift" ] || { echo "error: no Package.swift in $REPO (run from the app repo root)" >&2; exit 1; }

BUILD_DIR="$REPO/.build/package"
APP="$BUILD_DIR/$APP_NAME.app"

ICON="$REPO/Packaging/AppIcon.icns"
[ -f "$ICON" ] || { echo "error: $ICON not found (run make-icon.sh <emoji>)" >&2; exit 1; }

echo "Building universal binary..."
swift build -c release --arch arm64 --arch x86_64
BIN_DIR="$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path 2>/dev/null | tail -1)"
BINARY="$BIN_DIR/$APP_NAME"
[ -f "$BINARY" ] || { echo "error: expected universal binary at $BINARY, not found" >&2; exit 1; }

echo "Assembling app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BINARY" "$APP/Contents/MacOS/$APP_NAME"
sed -e "s/\$(VERSION)/$VERSION/g" -e "s/\$(BUILD_VERSION)/$BUILD_VERSION/g" "$REPO/Packaging/Info.plist" > "$APP/Contents/Info.plist"
cp "$ICON" "$APP/Contents/Resources/AppIcon.icns"

echo "Signing (ad-hoc)..."
codesign --force --options runtime -s - "$APP"

echo "Packaged: $APP"
