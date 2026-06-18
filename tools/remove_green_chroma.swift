import AppKit

guard CommandLine.arguments.count == 3 || CommandLine.arguments.count == 4 else {
    fatalError("Usage: swift tools/remove_green_chroma.swift <input.png> <output.png> [key-hex]")
}

let inputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let keyHex = CommandLine.arguments.count == 4 ? CommandLine.arguments[3] : "00ff00"

func colorComponents(from hex: String) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
    let normalized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard normalized.count == 6, let value = Int(normalized, radix: 16) else {
        fatalError("Key color must be a 6-digit hex value, for example ff00ff")
    }

    return (
        r: CGFloat((value >> 16) & 0xff) / 255.0,
        g: CGFloat((value >> 8) & 0xff) / 255.0,
        b: CGFloat(value & 0xff) / 255.0
    )
}

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

let key = colorComponents(from: keyHex)
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

        let maxNonKey = max(key.r > 0.8 ? 0 : r, key.g > 0.8 ? 0 : g, key.b > 0.8 ? 0 : b)
        let outputRed = alpha < 1 && key.r > 0.8 ? min(r, maxNonKey * 1.08) : r
        let outputGreen = alpha < 1 && key.g > 0.8 ? min(g, maxNonKey * 1.08) : g
        let outputBlue = alpha < 1 && key.b > 0.8 ? min(b, maxNonKey * 1.08) : b
        let output = NSColor(deviceRed: outputRed, green: outputGreen, blue: outputBlue, alpha: alpha)
        bitmap.setColor(output, atX: x, y: y)
    }
}

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode output")
}

try png.write(to: outputURL)
