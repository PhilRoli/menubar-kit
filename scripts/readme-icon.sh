#!/bin/bash
# Renders an icon as a macOS-style rounded app tile (white gradient, thin border, soft shadow) into a
# 256x256 PNG with transparent corners, for use in the README title. Run from the repo root.
#   readme-icon.sh                       Packaging/AppIcon.icns -> Packaging/icon.png
#   readme-icon.sh -e <emoji> [-o path]  an emoji (for CLI tools without an app bundle)
set -euo pipefail

REPO="$(pwd)"
ICNS="$REPO/Packaging/AppIcon.icns"
EMOJI=""
OUT="$REPO/Packaging/icon.png"
while getopts "e:o:" opt; do
    case "$opt" in
        e) EMOJI="$OPTARG" ;;
        o) OUT="$OPTARG" ;;
        *) echo "Usage: readme-icon.sh [-e <emoji>] [-o <output.png>]" >&2; exit 1 ;;
    esac
done
if [ -z "$EMOJI" ] && [ ! -f "$ICNS" ]; then
    echo "error: $ICNS not found (run make-icon.sh <emoji> first, or pass -e <emoji>)" >&2
    exit 1
fi
mkdir -p "$(dirname "$OUT")"

WORK="$(mktemp -d -t readme_icon)"
trap 'rm -rf "$WORK"' EXIT
RENDER_SCRIPT="$WORK/render.swift"

cat > "$RENDER_SCRIPT" <<'SWIFT'
import AppKit

let size: CGFloat = 256
let output = URL(fileURLWithPath: CommandLine.arguments[2])
let emoji = CommandLine.arguments[3]

func emojiImage(_ text: String) -> NSImage {
    let side: CGFloat = 1024
    let image = NSImage(size: NSSize(width: side, height: side))
    image.lockFocus()
    let string = NSAttributedString(string: text, attributes: [.font: NSFont.systemFont(ofSize: side * 0.72)])
    let extent = string.size()
    string.draw(at: NSPoint(x: (side - extent.width) / 2, y: (side - extent.height) / 2))
    image.unlockFocus()
    return image
}

let source = emoji.isEmpty
    ? NSImage(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))!
    : emojiImage(emoji)

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

swift "$RENDER_SCRIPT" "$ICNS" "$OUT" "$EMOJI"
echo "Wrote $OUT"
