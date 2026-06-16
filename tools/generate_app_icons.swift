import AppKit

struct IconSpec {
    let filename: String
    let pixels: Int
}

let specs: [IconSpec] = [
    .init(filename: "Icon-20.png", pixels: 20),
    .init(filename: "Icon-40.png", pixels: 40),
    .init(filename: "Icon-40-1.png", pixels: 40),
    .init(filename: "Icon-60.png", pixels: 60),
    .init(filename: "Icon-29.png", pixels: 29),
    .init(filename: "Icon-58.png", pixels: 58),
    .init(filename: "Icon-58-1.png", pixels: 58),
    .init(filename: "Icon-87.png", pixels: 87),
    .init(filename: "Icon-40-2.png", pixels: 40),
    .init(filename: "Icon-80.png", pixels: 80),
    .init(filename: "Icon-80-1.png", pixels: 80),
    .init(filename: "Icon-120.png", pixels: 120),
    .init(filename: "Icon-120-1.png", pixels: 120),
    .init(filename: "Icon-180.png", pixels: 180),
    .init(filename: "Icon-76.png", pixels: 76),
    .init(filename: "Icon-152.png", pixels: 152),
    .init(filename: "Icon-167.png", pixels: 167),
    .init(filename: "Icon-1024.png", pixels: 1024)
]

let outputDirectory = URL(fileURLWithPath: "GomokuApp/Resources/Assets.xcassets/AppIcon.appiconset")
let sourceURL = CommandLine.arguments.dropFirst().first.map(URL.init(fileURLWithPath:))
let sourceImage = sourceURL.flatMap(NSImage.init(contentsOf:))

for spec in specs {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: spec.pixels,
        pixelsHigh: spec.pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: spec.pixels * 4,
        bitsPerPixel: 32
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        fatalError("Could not create bitmap for \(spec.filename)")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    let rect = NSRect(origin: .zero, size: NSSize(width: spec.pixels, height: spec.pixels))
    if let sourceImage {
        NSColor.white.setFill()
        rect.fill()
        context.imageInterpolation = .high
        sourceImage.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    } else {
        NSColor(red: 0.96, green: 0.69, blue: 0.34, alpha: 1).setFill()
        rect.fill()

        let path = NSBezierPath(rect: rect)
        NSColor(red: 0.55, green: 0.30, blue: 0.14, alpha: 0.42).setStroke()
        path.lineWidth = max(1, CGFloat(spec.pixels) * 0.018)
        let gridInset = CGFloat(spec.pixels) * 0.18
        let gridSize = CGFloat(spec.pixels) - gridInset * 2
        let step = gridSize / 4

        for index in 0...4 {
            let offset = gridInset + CGFloat(index) * step
            let horizontal = NSBezierPath()
            horizontal.move(to: NSPoint(x: gridInset, y: offset))
            horizontal.line(to: NSPoint(x: gridInset + gridSize, y: offset))
            horizontal.stroke()

            let vertical = NSBezierPath()
            vertical.move(to: NSPoint(x: offset, y: gridInset))
            vertical.line(to: NSPoint(x: offset, y: gridInset + gridSize))
            vertical.stroke()
        }

        func stone(center: NSPoint, radius: CGFloat, color: NSColor) {
            color.setFill()
            NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
        }

        let radius = CGFloat(spec.pixels) * 0.105
        stone(center: NSPoint(x: gridInset + step * 1, y: gridInset + step * 2), radius: radius, color: .black)
        stone(center: NSPoint(x: gridInset + step * 2, y: gridInset + step * 2), radius: radius, color: .white)
        stone(center: NSPoint(x: gridInset + step * 3, y: gridInset + step * 2), radius: radius, color: .black)
        stone(center: NSPoint(x: gridInset + step * 2, y: gridInset + step * 1), radius: radius, color: .black)
        stone(center: NSPoint(x: gridInset + step * 2, y: gridInset + step * 3), radius: radius, color: .black)
    }

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(spec.filename)")
    }

    try png.write(to: outputDirectory.appendingPathComponent(spec.filename))
}
