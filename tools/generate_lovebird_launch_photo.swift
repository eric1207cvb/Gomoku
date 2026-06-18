import AppKit

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift tools/generate_lovebird_launch_photo.swift <input-image> <output-png>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let sourceImage = NSImage(contentsOf: inputURL),
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: 768,
        pixelsHigh: 1024,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 768 * 4,
        bitsPerPixel: 32
      ),
      let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create launch photo")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

let rect = NSRect(x: 0, y: 0, width: 768, height: 1024)
NSColor.white.setFill()
rect.fill()

// A light white blend keeps the real photo, but makes the overall launch image softer.
sourceImage.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 0.88)

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode launch photo")
}

try png.write(to: outputURL)
