#!/usr/bin/env swift

import AppKit
import Foundation

let rootURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resourcesURL = rootURL.appendingPathComponent("Resources", isDirectory: true)
let iconsetURL = resourcesURL.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = resourcesURL.appendingPathComponent("AppIcon.icns")

try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let specs: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for spec in specs {
    let image = drawIcon(size: spec.pixels)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(spec.name)")
    }

    try png.write(to: iconsetURL.appendingPathComponent(spec.name), options: .atomic)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
    "-c",
    "icns",
    iconsetURL.path,
    "-o",
    icnsURL.path,
]

try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fatalError("iconutil failed with status \(process.terminationStatus)")
}

try FileManager.default.removeItem(at: iconsetURL)
print(icnsURL.path)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size, height: size).fill()

    let scale = size / 144.0
    let context = NSGraphicsContext.current!.cgContext
    context.saveGState()
    context.translateBy(x: 0, y: size)
    context.scaleBy(x: scale, y: -scale)
    context.translateBy(x: 0, y: 23)

    drawEyes()

    context.restoreGState()
    image.unlockFocus()
    return image
}

func drawEyes() {
    let eyeCenters: [CGFloat] = [44, 100]
    let eyeY: CGFloat = 48
    let eyeRx: CGFloat = 28
    let eyeRy: CGFloat = 36
    let stroke = NSColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1)
    let eyeFill = NSColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1)

    for (index, centerX) in eyeCenters.enumerated() {
        stroke.setStroke()
        let brow = browPath(centerX: centerX, eyeIndex: index)
        brow.lineWidth = 4.3
        brow.lineCapStyle = .round
        brow.stroke()

        let eyeRect = NSRect(x: centerX - eyeRx, y: eyeY - eyeRy, width: eyeRx * 2, height: eyeRy * 2)
        let eye = NSBezierPath(ovalIn: eyeRect)
        eyeFill.setFill()
        eye.fill()
        stroke.withAlphaComponent(0.88).setStroke()
        eye.lineWidth = 2.8
        eye.stroke()

        let pupilX = centerX + (index == 0 ? -2 : 2)
        let pupilY = eyeY - 1
        stroke.setFill()
        NSBezierPath(ovalIn: NSRect(x: pupilX - 14, y: pupilY - 14, width: 28, height: 28)).fill()

        NSColor.white.withAlphaComponent(0.92).setFill()
        NSBezierPath(ovalIn: NSRect(x: pupilX - 8, y: pupilY + 3, width: 8, height: 8)).fill()

        stroke.withAlphaComponent(0.22).setStroke()
        let lower = NSBezierPath()
        lower.move(to: NSPoint(x: centerX - 22, y: eyeY + eyeRy - 6))
        lower.curve(
            to: NSPoint(x: centerX + 22, y: eyeY + eyeRy - 6),
            controlPoint1: NSPoint(x: centerX - 8, y: eyeY + eyeRy + 2),
            controlPoint2: NSPoint(x: centerX + 8, y: eyeY + eyeRy + 2)
        )
        lower.lineWidth = 2.1
        lower.lineCapStyle = .round
        lower.stroke()

        stroke.withAlphaComponent(0.25).setStroke()
        let crease = NSBezierPath()
        crease.move(to: NSPoint(x: centerX - 21, y: 24 + (index == 0 ? 2 : -1)))
        crease.curve(
            to: NSPoint(x: centerX + 21, y: 24 + (index == 0 ? -1 : 2)),
            controlPoint1: NSPoint(x: centerX - 9, y: 16),
            controlPoint2: NSPoint(x: centerX + 9, y: 16)
        )
        crease.lineWidth = 2.0
        crease.lineCapStyle = .round
        crease.stroke()
    }
}

func browPath(centerX: CGFloat, eyeIndex: Int) -> NSBezierPath {
    let path = NSBezierPath()
    if eyeIndex == 0 {
        path.move(to: NSPoint(x: centerX - 24, y: 12))
        path.curve(
            to: NSPoint(x: centerX + 8, y: 10),
            controlPoint1: NSPoint(x: centerX - 14, y: 2),
            controlPoint2: NSPoint(x: centerX - 3, y: 2)
        )
    } else {
        path.move(to: NSPoint(x: centerX - 8, y: 10))
        path.curve(
            to: NSPoint(x: centerX + 24, y: 12),
            controlPoint1: NSPoint(x: centerX + 3, y: 2),
            controlPoint2: NSPoint(x: centerX + 14, y: 2)
        )
    }
    return path
}
