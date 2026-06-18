import AppKit

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "GomokuApp/Resources/Assets.xcassets/GomokuMascots.imageset/gomoku-mascots.png")
let side = 1254

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: side,
    pixelsHigh: side,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: side * 4,
    bitsPerPixel: 32
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Could not create mascot bitmap")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.shouldAntialias = true

let canvas = NSRect(x: 0, y: 0, width: side, height: side)
NSColor.clear.setFill()
canvas.fill()

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func fillStar(center: NSPoint, radius: CGFloat, color: NSColor) {
    let path = NSBezierPath()
    for index in 0..<10 {
        let angle = CGFloat(index) * .pi / 5 - .pi / 2
        let currentRadius = index.isMultiple(of: 2) ? radius : radius * 0.44
        let point = NSPoint(
            x: center.x + cos(angle) * currentRadius,
            y: center.y + sin(angle) * currentRadius
        )
        index == 0 ? path.move(to: point) : path.line(to: point)
    }
    path.close()
    color.setFill()
    path.fill()
}

func fillCircle(center: NSPoint, radius: CGFloat, color: NSColor) {
    color.setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
}

func drawStone(center: NSPoint, radius: CGFloat, isBlack: Bool, wink: Bool = false) {
    let rect = NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
    let colors: [NSColor] = isBlack
        ? [
            NSColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1),
            NSColor(red: 0.18, green: 0.18, blue: 0.24, alpha: 1)
        ]
        : [
            NSColor(red: 1.00, green: 0.99, blue: 0.94, alpha: 1),
            NSColor(red: 0.86, green: 0.83, blue: 0.78, alpha: 1)
        ]

    NSGradient(colors: colors)?.draw(in: NSBezierPath(ovalIn: rect), angle: 90)
    NSColor.black.withAlphaComponent(0.12).setStroke()
    let outline = NSBezierPath(ovalIn: rect.insetBy(dx: radius * 0.02, dy: radius * 0.02))
    outline.lineWidth = max(2, radius * 0.04)
    outline.stroke()

    NSColor.white.withAlphaComponent(isBlack ? 0.58 : 0.9).setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - radius * 0.36, y: center.y + radius * 0.28, width: radius * 0.33, height: radius * 0.25)).fill()

    let face = isBlack ? NSColor.white : NSColor(red: 0.12, green: 0.08, blue: 0.10, alpha: 1)
    face.setFill()
    if wink {
        let winkPath = NSBezierPath()
        winkPath.move(to: NSPoint(x: center.x + radius * 0.18, y: center.y + radius * 0.12))
        winkPath.curve(
            to: NSPoint(x: center.x + radius * 0.44, y: center.y + radius * 0.12),
            controlPoint1: NSPoint(x: center.x + radius * 0.26, y: center.y + radius * 0.03),
            controlPoint2: NSPoint(x: center.x + radius * 0.36, y: center.y + radius * 0.03)
        )
        winkPath.lineWidth = max(2.5, radius * 0.08)
        face.setStroke()
        winkPath.stroke()
    } else {
        fillCircle(center: NSPoint(x: center.x + radius * 0.32, y: center.y + radius * 0.12), radius: radius * 0.08, color: face)
    }
    fillCircle(center: NSPoint(x: center.x - radius * 0.22, y: center.y + radius * 0.12), radius: radius * 0.08, color: face)

    let smile = NSBezierPath()
    smile.move(to: NSPoint(x: center.x - radius * 0.14, y: center.y - radius * 0.10))
    smile.curve(
        to: NSPoint(x: center.x + radius * 0.14, y: center.y - radius * 0.10),
        controlPoint1: NSPoint(x: center.x - radius * 0.05, y: center.y - radius * 0.24),
        controlPoint2: NSPoint(x: center.x + radius * 0.05, y: center.y - radius * 0.24)
    )
    smile.lineWidth = max(2.5, radius * 0.07)
    face.setStroke()
    smile.stroke()

    fillCircle(center: NSPoint(x: center.x - radius * 0.42, y: center.y - radius * 0.06), radius: radius * 0.11, color: NSColor(red: 1.0, green: 0.42, blue: 0.48, alpha: isBlack ? 0.78 : 0.64))
    fillCircle(center: NSPoint(x: center.x + radius * 0.48, y: center.y - radius * 0.06), radius: radius * 0.11, color: NSColor(red: 1.0, green: 0.42, blue: 0.48, alpha: isBlack ? 0.78 : 0.64))
}

fillStar(center: NSPoint(x: 228, y: 1015), radius: 54, color: NSColor(red: 1.0, green: 0.78, blue: 0.20, alpha: 0.95))
fillStar(center: NSPoint(x: 1012, y: 1012), radius: 46, color: NSColor(red: 1.0, green: 0.60, blue: 0.72, alpha: 0.95))
fillStar(center: NSPoint(x: 1038, y: 224), radius: 42, color: NSColor(red: 0.42, green: 0.82, blue: 0.98, alpha: 0.95))
fillStar(center: NSPoint(x: 210, y: 250), radius: 45, color: NSColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 0.95))
fillCircle(center: NSPoint(x: 162, y: 760), radius: 17, color: NSColor(red: 0.52, green: 0.90, blue: 0.86, alpha: 0.9))
fillCircle(center: NSPoint(x: 1088, y: 676), radius: 13, color: NSColor(red: 1.0, green: 0.86, blue: 0.28, alpha: 0.9))
fillCircle(center: NSPoint(x: 780, y: 1086), radius: 12, color: NSColor(red: 1.0, green: 0.60, blue: 0.74, alpha: 0.88))

let boardRect = NSRect(x: 198, y: 188, width: 858, height: 858)
NSGraphicsContext.saveGraphicsState()
NSShadow().apply {
    $0.shadowColor = NSColor.black.withAlphaComponent(0.16)
    $0.shadowBlurRadius = 26
    $0.shadowOffset = NSSize(width: 0, height: -12)
}
NSGradient(colors: [
    NSColor(red: 1.00, green: 0.80, blue: 0.42, alpha: 1),
    NSColor(red: 0.98, green: 0.60, blue: 0.30, alpha: 1)
])?.draw(in: roundedRect(boardRect, radius: 58), angle: -35)
NSGraphicsContext.restoreGraphicsState()

NSColor(red: 0.58, green: 0.34, blue: 0.15, alpha: 0.38).setStroke()
let boardOutline = roundedRect(boardRect.insetBy(dx: 16, dy: 16), radius: 44)
boardOutline.lineWidth = 7
boardOutline.stroke()

let gridInset: CGFloat = 92
let gridRect = boardRect.insetBy(dx: gridInset, dy: gridInset)
let gridCount = 14
let step = gridRect.width / CGFloat(gridCount)
NSColor(red: 0.45, green: 0.26, blue: 0.13, alpha: 0.55).setStroke()
for index in 0...gridCount {
    let offset = CGFloat(index) * step
    let horizontal = NSBezierPath()
    horizontal.move(to: NSPoint(x: gridRect.minX, y: gridRect.minY + offset))
    horizontal.line(to: NSPoint(x: gridRect.maxX, y: gridRect.minY + offset))
    horizontal.lineWidth = 3
    horizontal.stroke()

    let vertical = NSBezierPath()
    vertical.move(to: NSPoint(x: gridRect.minX + offset, y: gridRect.minY))
    vertical.line(to: NSPoint(x: gridRect.minX + offset, y: gridRect.maxY))
    vertical.lineWidth = 3
    vertical.stroke()
}

for point in [(3, 3), (7, 3), (11, 3), (3, 7), (7, 7), (11, 7), (3, 11), (7, 11), (11, 11)] {
    fillCircle(
        center: NSPoint(x: gridRect.minX + CGFloat(point.0) * step, y: gridRect.minY + CGFloat(point.1) * step),
        radius: 8,
        color: NSColor(red: 1.0, green: 0.92, blue: 0.44, alpha: 0.9)
    )
}

let stoneRadius: CGFloat = 58
let stones: [(CGFloat, CGFloat, Bool, Bool)] = [
    (3.1, 4.0, false, false),
    (4.5, 5.1, true, false),
    (5.9, 6.2, false, true),
    (7.3, 7.3, true, false),
    (8.7, 8.4, false, false)
]
for stone in stones {
    drawStone(
        center: NSPoint(x: gridRect.minX + stone.0 * step, y: gridRect.minY + stone.1 * step),
        radius: stoneRadius,
        isBlack: stone.2,
        wink: stone.3
    )
}

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode mascot PNG")
}

try png.write(to: outputURL)

private extension NSShadow {
    func apply(_ configure: (NSShadow) -> Void) {
        configure(self)
        set()
    }
}
