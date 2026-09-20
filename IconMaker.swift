import AppKit

// Reuses the original monster art to create a macOS-sized application icon.
@main
struct IconMaker {
    static func main() throws {
        guard CommandLine.arguments.count == 3,
              let monster = NSImage(contentsOfFile: CommandLine.arguments[1]),
              let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024,
                                            pixelsHigh: 1024, bitsPerSample: 8,
                                            samplesPerPixel: 4, hasAlpha: true,
                                            isPlanar: false, colorSpaceName: .deviceRGB,
                                            bytesPerRow: 0, bitsPerPixel: 0),
              let graphics = NSGraphicsContext(bitmapImageRep: bitmap) else {
            throw NSError(domain: "IconMaker", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Need a source PNG and output PNG path"])
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        defer { NSGraphicsContext.restoreGraphicsState() }
        NSColor.clear.setFill()
        NSRect(x: 0, y: 0, width: 1024, height: 1024).fill()

        let tile = NSBezierPath(roundedRect: NSRect(x: 48, y: 48, width: 928, height: 928),
                                xRadius: 205, yRadius: 205)
        NSGradient(starting: NSColor(red: 0.32, green: 0.015, blue: 0.03, alpha: 1),
                   ending: NSColor(red: 0.035, green: 0.005, blue: 0.015, alpha: 1))!
            .draw(in: tile, angle: 135)

        NSGradient(starting: NSColor(red: 1, green: 0.08, blue: 0.07, alpha: 0.78),
                   ending: NSColor(red: 0.7, green: 0.03, blue: 0.05, alpha: 0))!
            .draw(in: NSBezierPath(ovalIn: NSRect(x: 162, y: 125, width: 700, height: 775)),
                  relativeCenterPosition: .zero)

        graphics.imageInterpolation = .none // keep the monster's original glitchy pixels
        monster.draw(in: NSRect(x: 142, y: 112, width: 740, height: 790),
                     from: .zero, operation: .sourceOver, fraction: 1)
        NSColor(red: 1, green: 0.16, blue: 0.17, alpha: 0.72).setStroke()
        tile.lineWidth = 12
        tile.stroke()
        graphics.flushGraphics()

        guard let png = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "IconMaker", code: 2)
        }
        try png.write(to: URL(fileURLWithPath: CommandLine.arguments[2]), options: .atomic)
    }
}
