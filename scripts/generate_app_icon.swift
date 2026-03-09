#!/usr/bin/env swift

import AppKit

let fileManager = FileManager.default
let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/app-icon-1024.png"
let outputURL = URL(fileURLWithPath: outputPath, relativeTo: currentDirectory).standardizedFileURL

let canvasSize = 1024

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: canvasSize, pixelsHigh: canvasSize,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { fputs("Cannot create bitmap\n", stderr); exit(1) }

guard let gfx = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fputs("Cannot create context\n", stderr); exit(1)
}

// --- SF Symbol rendering ---
func drawSymbol(_ name: String, pointSize: CGFloat, weight: NSFont.Weight, color: NSColor, center: NSPoint) {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil) else {
        fputs("SF Symbol '\(name)' not found\n", stderr)
        return
    }
    let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
    guard let sym = base.withSymbolConfiguration(config) else { return }
    let s = sym.size
    print("  \(name) at \(pointSize)pt → \(s.width) × \(s.height)")

    let tinted = NSImage(size: s)
    tinted.lockFocus()
    sym.draw(in: NSRect(origin: .zero, size: s), from: .zero, operation: .sourceOver, fraction: 1.0)
    color.set()
    NSRect(origin: .zero, size: s).fill(using: .sourceAtop)
    tinted.unlockFocus()

    let r = NSRect(x: center.x - s.width / 2, y: center.y - s.height / 2, width: s.width, height: s.height)
    tinted.draw(in: r, from: .zero, operation: .sourceOver, fraction: 1.0)
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = gfx

let canvas = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

// --- Background squircle ---
let bgPath = NSBezierPath(roundedRect: canvas.insetBy(dx: 10, dy: 10), xRadius: 220, yRadius: 220)

NSGradient(colors: [
    NSColor(calibratedRed: 0.14, green: 0.15, blue: 0.19, alpha: 1.0),
    NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.09, alpha: 1.0)
])!.draw(in: bgPath, angle: 270)

// Subtle top highlight for depth
NSGradient(colors: [
    NSColor(calibratedWhite: 1.0, alpha: 0.04),
    NSColor(calibratedWhite: 1.0, alpha: 0.0)
])!.draw(in: bgPath, angle: 90)

// Fine border
NSColor(calibratedWhite: 1.0, alpha: 0.06).setStroke()
bgPath.lineWidth = 1.5
bgPath.stroke()

// --- Viewfinder (large, centered) ---
drawSymbol("viewfinder", pointSize: 600, weight: .light,
           color: NSColor(calibratedWhite: 1.0, alpha: 0.75),
           center: NSPoint(x: 512, y: 512))

// --- Heart (left of center, inside viewfinder) ---
drawSymbol("heart.fill", pointSize: 110, weight: .regular,
           color: NSColor(calibratedRed: 1.0, green: 0.30, blue: 0.36, alpha: 0.88),
           center: NSPoint(x: 420, y: 475))

// --- Bolt (right of center, inside viewfinder) ---
drawSymbol("bolt.fill", pointSize: 110, weight: .regular,
           color: NSColor(calibratedRed: 0.25, green: 0.60, blue: 1.0, alpha: 0.88),
           center: NSPoint(x: 610, y: 475))

NSGraphicsContext.restoreGraphicsState()

// --- Save ---
try fileManager.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Cannot encode PNG\n", stderr); exit(1)
}
try pngData.write(to: outputURL)
print("Wrote \(outputURL.path)")
