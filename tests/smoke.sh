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

# a leftover temp file from a crashed run must not block later runs
touch /tmp/render_icon.XXXXXX.swift
"$KIT/scripts/make-icon.sh" "🧪"
rm -f /tmp/render_icon.XXXXXX.swift
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

# README icon: rounded app-tile PNG with transparent corners and an opaque centre
rm -f Packaging/icon.png
"$KIT/scripts/readme-icon.sh" >/dev/null
[ -f Packaging/icon.png ] || fail "readme icon not generated"
python3 - Packaging/icon.png <<'PY' || fail "readme icon pixels wrong"
import struct, sys, zlib
data = open(sys.argv[1], "rb").read()
assert data[:8] == b"\x89PNG\r\n\x1a\n"
pos, idat, w = 8, b"", 0
while pos < len(data):
    n, kind = struct.unpack(">I4s", data[pos:pos + 8])
    body = data[pos + 8:pos + 8 + n]
    if kind == b"IHDR":
        w, h, depth, ctype = struct.unpack(">IIBB", body[:10])
        assert (w, h, depth, ctype) == (256, 256, 8, 6), (w, h, depth, ctype)
    if kind == b"IDAT":
        idat += body
    pos += 12 + n
raw = zlib.decompress(idat)
stride = 1 + w * 4
rows, prev = [], bytearray(w * 4)
for y in range(w):
    f, line = raw[y * stride], bytearray(raw[y * stride + 1:(y + 1) * stride])
    for i in range(len(line)):
        a = line[i - 4] if i >= 4 else 0
        b = prev[i]
        c = prev[i - 4] if i >= 4 else 0
        if f == 1: line[i] = (line[i] + a) & 255
        elif f == 2: line[i] = (line[i] + b) & 255
        elif f == 3: line[i] = (line[i] + (a + b) // 2) & 255
        elif f == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            line[i] = (line[i] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
    rows.append(line)
    prev = line
alpha = lambda x, y: rows[y][x * 4 + 3]
assert alpha(0, 0) == 0 and alpha(255, 255) == 0, "corners must be transparent"
assert alpha(128, 40) == 255, "tile body must be opaque"
PY

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
