#!/bin/bash
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$KIT/tests/fixture"

fail() { echo "FAIL: $*" >&2; exit 1; }

# missing Package.swift -> clear error
OUT="$(cd "$(mktemp -d)" && "$KIT/scripts/package-app.sh" Fixture 1.0.0 2>&1 || true)"
echo "$OUT" | grep -q "Package.swift" || fail "no clear error outside an app repo"

# missing icon -> loud failure
rm -f Packaging/AppIcon.icns
if "$KIT/scripts/package-app.sh" Fixture 1.2.3-rc.1 >/dev/null 2>&1; then fail "packaging succeeded without icon"; fi

"$KIT/scripts/make-icon.sh" "🧪"
[ -f Packaging/AppIcon.icns ] || fail "icon not generated"

"$KIT/scripts/package-app.sh" Fixture 1.2.3-rc.1
APP=.build/package/Fixture.app
[ -x "$APP/Contents/MacOS/Fixture" ] || fail "binary missing"
[ -f "$APP/Contents/Resources/AppIcon.icns" ] || fail "icon missing"
PLIST="$APP/Contents/Info.plist"
[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$PLIST")" = "1.2.3-rc.1" ] || fail "short version"
[ "$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$PLIST")" = "1.2.3" ] || fail "build version not numeric"
lipo -archs "$APP/Contents/MacOS/Fixture" | grep -q arm64 || fail "not universal"
codesign --verify "$APP" || fail "signature invalid"
echo "OK"
