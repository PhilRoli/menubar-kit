#!/bin/bash
set -euo pipefail
KIT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$KIT/tests/fixture"

fail() { echo "FAIL: $*" >&2; exit 1; }

# missing Package.swift -> clear error
OUT="$(cd "$(mktemp -d)" && "$KIT/scripts/package-app.sh" Fixture 1.0.0 2>&1 || true)"
echo "$OUT" | grep -q "Package.swift" || fail "no clear error outside an app repo"

# missing icon -> loud failure
rm -f Packaging/AppIcon.icns Packaging/Fixture.entitlements
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

# default signing is NOT hardened runtime (breaks Apple Events without entitlements)
SIG="$(codesign -d --verbose=4 "$APP" 2>&1)"
if echo "$SIG" | grep -q "runtime"; then fail "hardened runtime enabled without entitlements"; fi
# an entitlements file opts in to hardened runtime + entitlements
cat > Packaging/Fixture.entitlements <<'PL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.automation.apple-events</key><true/></dict></plist>
PL
"$KIT/scripts/package-app.sh" Fixture 1.2.3 >/dev/null 2>&1
SIG="$(codesign -d --verbose=4 "$APP" 2>&1)"
echo "$SIG" | grep -q "runtime" || fail "entitlements file did not enable hardened runtime"
ENT="$(codesign -d --entitlements - "$APP" 2>&1)"
echo "$ENT" | grep -q "apple-events" || fail "entitlements not applied"
rm -f Packaging/Fixture.entitlements

# prerelease detection
"$KIT/scripts/is-prerelease.sh" v1.2.3-rc.1 || fail "rc not detected as prerelease"
if "$KIT/scripts/is-prerelease.sh" v1.2.3; then fail "stable tag detected as prerelease"; fi

# cask update: exact substitutions, loud on mismatch
T="$(mktemp -d)"
printf 'cask "x" do\n  version "1.0.0"\n  sha256 "aaa"\nend\n' > "$T/good.rb"
"$KIT/scripts/update-cask.py" "$T/good.rb" 2.0.0 bbb || fail "update-cask rejected a valid cask"
grep -q 'version "2.0.0"' "$T/good.rb" && grep -q 'sha256 "bbb"' "$T/good.rb" || fail "cask not updated"
printf "cask 'x' do\n  version '1.0.0'\n  sha256 :no_check\nend\n" > "$T/odd.rb"
if "$KIT/scripts/update-cask.py" "$T/odd.rb" 2.0.0 bbb 2>/dev/null; then fail "update-cask silently accepted an unmatched cask"; fi
echo "OK"
