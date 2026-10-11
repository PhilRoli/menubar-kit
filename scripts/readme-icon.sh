#!/bin/bash
# Renders Packaging/AppIcon.icns as a macOS-style rounded app tile (white gradient, thin border, soft shadow)
# into Packaging/icon.png (256x256, transparent corners) for use in the README title. Run from the app repo root.
set -euo pipefail

REPO="$(pwd)"
ICNS="$REPO/Packaging/AppIcon.icns"
[ -f "$ICNS" ] || { echo "error: $ICNS not found (run make-icon.sh <emoji> first)" >&2; exit 1; }

WORK="$(mktemp -d -t readme_icon)"
trap 'rm -rf "$WORK"' EXIT
RENDER_SCRIPT="$WORK/render.swift"

cat > "$RENDER_SCRIPT" <<'SWIFT'
import AppKit

let size: CGFloat = 256
let source = NSImage(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))!
let output = URL(fileURLWithPath: CommandLine.arguments[2])

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4,
    hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: rep) else { fatalError("no bitmap context") }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

let inset = size * 0.09
let tile = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
let radius = tile.width * 0.2237 // macOS app icon corner ratio
let path = NSBezierPath(roundedRect: tile, xRadius: radius, yRadius: radius)

NSGraphicsContext.saveGraphicsState()
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
shadow.shadowOffset = NSSize(width: 0, height: -3)
shadow.shadowBlurRadius = 6
shadow.set()
NSColor.white.setFill()
path.fill()
NSGraphicsContext.restoreGraphicsState()

NSGradient(starting: NSColor.white, ending: NSColor(white: 0.90, alpha: 1))!.draw(in: path, angle: -90)

NSColor.black.withAlphaComponent(0.18).setStroke()
path.lineWidth = 1.5
path.stroke()

let glyph = tile.insetBy(dx: tile.width * 0.03, dy: tile.height * 0.03)
source.draw(in: glyph, from: .zero, operation: .sourceOver, fraction: 1)

NSGraphicsContext.restoreGraphicsState()
try rep.representation(using: .png, properties: [:])!.write(to: output)
SWIFT

swift "$RENDER_SCRIPT" "$ICNS" "$REPO/Packaging/icon.png"
echo "Wrote Packaging/icon.png"
