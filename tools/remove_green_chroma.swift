import AppKit

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: swift tools/remove_green_chroma.swift <input.png> <output.png>")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let image = NSImage(contentsOf: inputURL),
      let tiff = image.tiffRepresentation,
      let source = NSBitmapImageRep(data: tiff),
      let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: source.pixelsWide,
        pixelsHigh: source.pixelsHigh,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: source.pixelsWide * 4,
        bitsPerPixel: 32
      ) else {
    fatalError("Could not open input image")
}

let key = (r: 0.0, g: 1.0, b: 0.0)
let transparentThreshold = 0.30
let featherThreshold = 0.72

for y in 0..<source.pixelsHigh {
    for x in 0..<source.pixelsWide {
        guard let color = source.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
        let r = color.redComponent
        let g = color.greenComponent
        let b = color.blueComponent
        let distance = sqrt(pow(r - key.r, 2) + pow(g - key.g, 2) + pow(b - key.b, 2))

        let alpha: CGFloat
        if distance < transparentThreshold {
            alpha = 0
        } else if distance < featherThreshold {
            let t = (distance - transparentThreshold) / (featherThreshold - transparentThreshold)
            alpha = CGFloat(min(1.0, max(0.0, t)))
        } else {
            alpha = color.alphaComponent
        }

        let despill = alpha < 1 ? min(g, max(r, b) * 1.08) : g
        let output = NSColor(deviceRed: r, green: despill, blue: b, alpha: alpha)
        bitmap.setColor(output, atX: x, y: y)
    }
}

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode output")
}

try png.write(to: outputURL)
