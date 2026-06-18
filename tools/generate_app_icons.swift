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

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawGlossyStone(center: NSPoint, radius: CGFloat, black: Bool) {
    let rect = NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let path = NSBezierPath(ovalIn: rect)
    let colors: [NSColor] = black
        ? [
            NSColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1),
            NSColor(red: 0.18, green: 0.18, blue: 0.22, alpha: 1)
        ]
        : [
            NSColor(red: 1.0, green: 0.98, blue: 0.91, alpha: 1),
            NSColor(red: 0.78, green: 0.74, blue: 0.66, alpha: 1)
        ]

    NSGradient(colors: colors)?.draw(in: path, angle: 100)
    NSColor.black.withAlphaComponent(black ? 0.16 : 0.20).setStroke()
    path.lineWidth = max(1, radius * 0.045)
    path.stroke()

    NSColor.white.withAlphaComponent(black ? 0.50 : 0.86).setFill()
    NSBezierPath(ovalIn: NSRect(
        x: center.x - radius * 0.38,
        y: center.y + radius * 0.22,
        width: radius * 0.36,
        height: radius * 0.24
    )).fill()
}

func drawIcon(in rect: NSRect, pixels: Int, sourceImage: NSImage?) {
    if let sourceImage {
        NSColor.white.setFill()
        rect.fill()
        NSGraphicsContext.current?.imageInterpolation = .high
        sourceImage.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
        return
    }

    NSGradient(colors: [
        NSColor(red: 0.86, green: 0.96, blue: 0.91, alpha: 1),
        NSColor(red: 1.00, green: 0.91, blue: 0.74, alpha: 1)
    ])?.draw(in: rect, angle: -38)

    let side = CGFloat(pixels)
    let boardRect = rect.insetBy(dx: side * 0.095, dy: side * 0.095)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.20)
    shadow.shadowBlurRadius = side * 0.035
    shadow.shadowOffset = NSSize(width: 0, height: -side * 0.014)
    shadow.set()

    NSGradient(colors: [
        NSColor(red: 1.00, green: 0.78, blue: 0.42, alpha: 1),
        NSColor(red: 0.96, green: 0.55, blue: 0.28, alpha: 1)
    ])?.draw(in: roundedRect(boardRect, radius: side * 0.055), angle: -32)
    NSGraphicsContext.restoreGraphicsState()

    let borderPath = roundedRect(boardRect.insetBy(dx: side * 0.014, dy: side * 0.014), radius: side * 0.043)
    NSColor(red: 0.48, green: 0.27, blue: 0.13, alpha: 0.36).setStroke()
    borderPath.lineWidth = max(1, side * 0.014)
    borderPath.stroke()

    let gridInset = side * 0.18
    let gridSize = side - gridInset * 2
    let lines = 10
    let step = gridSize / CGFloat(lines)
    NSColor(red: 0.36, green: 0.20, blue: 0.10, alpha: 0.48).setStroke()

    for index in 0...lines {
        let offset = gridInset + CGFloat(index) * step
        let horizontal = NSBezierPath()
        horizontal.move(to: NSPoint(x: gridInset, y: offset))
        horizontal.line(to: NSPoint(x: gridInset + gridSize, y: offset))
        horizontal.lineWidth = max(0.75, side * 0.0048)
        horizontal.stroke()

        let vertical = NSBezierPath()
        vertical.move(to: NSPoint(x: offset, y: gridInset))
        vertical.line(to: NSPoint(x: offset, y: gridInset + gridSize))
        vertical.lineWidth = max(0.75, side * 0.0048)
        vertical.stroke()
    }

    NSColor(red: 1.0, green: 0.91, blue: 0.43, alpha: 0.90).setFill()
    for dot in [(2, 2), (5, 2), (8, 2), (2, 5), (5, 5), (8, 5), (2, 8), (5, 8), (8, 8)] {
        let dotCenter = NSPoint(
            x: gridInset + CGFloat(dot.0) * step,
            y: gridInset + CGFloat(dot.1) * step
        )
        let radius = max(1.2, side * 0.010)
        NSBezierPath(ovalIn: NSRect(x: dotCenter.x - radius, y: dotCenter.y - radius, width: radius * 2, height: radius * 2)).fill()
    }

    let stoneRadius = side * 0.071
    let blackLine: [(CGFloat, CGFloat)] = [
        (2.4, 3.0),
        (3.55, 4.15),
        (4.7, 5.30),
        (5.85, 6.45),
        (7.0, 7.60)
    ]
    for point in blackLine {
        drawGlossyStone(
            center: NSPoint(x: gridInset + point.0 * step, y: gridInset + point.1 * step),
            radius: stoneRadius,
            black: true
        )
    }

    drawGlossyStone(
        center: NSPoint(x: gridInset + 7.2 * step, y: gridInset + 4.25 * step),
        radius: stoneRadius * 0.86,
        black: false
    )

    let lastMoveCenter = NSPoint(x: gridInset + 7.0 * step, y: gridInset + 7.60 * step)
    NSColor(red: 1.0, green: 0.86, blue: 0.24, alpha: 0.96).setStroke()
    let ring = NSBezierPath(ovalIn: NSRect(
        x: lastMoveCenter.x - stoneRadius * 1.22,
        y: lastMoveCenter.y - stoneRadius * 1.22,
        width: stoneRadius * 2.44,
        height: stoneRadius * 2.44
    ))
    ring.lineWidth = max(1.5, side * 0.009)
    ring.stroke()

    let feather = NSBezierPath()
    feather.move(to: NSPoint(x: side * 0.16, y: side * 0.80))
    feather.curve(
        to: NSPoint(x: side * 0.30, y: side * 0.92),
        controlPoint1: NSPoint(x: side * 0.19, y: side * 0.91),
        controlPoint2: NSPoint(x: side * 0.27, y: side * 0.96)
    )
    feather.curve(
        to: NSPoint(x: side * 0.21, y: side * 0.78),
        controlPoint1: NSPoint(x: side * 0.29, y: side * 0.84),
        controlPoint2: NSPoint(x: side * 0.24, y: side * 0.80)
    )
    feather.close()
    NSColor(red: 0.24, green: 0.66, blue: 0.63, alpha: 0.82).setFill()
    feather.fill()
}

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
    drawIcon(in: rect, pixels: spec.pixels, sourceImage: sourceImage)

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Could not render \(spec.filename)")
    }

    try png.write(to: outputDirectory.appendingPathComponent(spec.filename))
}
