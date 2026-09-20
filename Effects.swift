import AppKit

final class Soundtrack {
    private var current: NSSound?
    private var layer = 0

    func update(elapsed: Int, duration: Int) {
        let firstBoundary = max(1, (duration - 26) / 2)
        let thirdBoundary = max(firstBoundary + 1, duration - 26)
        let target = elapsed >= thirdBoundary ? 3 : (elapsed >= firstBoundary ? 2 : 1)
        guard target != layer else { return }
        stop()
        guard let path = Bundle.main.path(forResource: "layer\(target)", ofType: "wav"),
              let sound = NSSound(contentsOfFile: path, byReference: false) else { return }
        sound.volume = 0.22
        sound.loops = true
        sound.play()
        current = sound
        layer = target
    }

    func stop() {
        current?.stop()
        current = nil
        layer = 0
    }
}

final class TauntManager {
    private var windows: [NSWindow] = []
    private let imageNames = ["glitch1", "glitch2", "glitch3", "glitch4", "glitch5", "idiot", "tauntface", "tauntflower"]
    private let titles = ["RANS0M", "I FOUND YOU", "ERROR", "GIVE MONEY", "IMG.JPG", "YOU ARE AN IDIOT", "MOSNAR", "Untitled"]

    func spawn(count: Int) {
        for _ in 0..<count { spawnOne() }
    }

    func spawnOne() {
        guard windows.count < 8, let screen = NSScreen.main else { return }
        let size = CGFloat.random(in: 165...275)
        let visible = screen.visibleFrame
        let x = CGFloat.random(in: visible.minX...max(visible.minX, visible.maxX - size))
        let y = CGFloat.random(in: visible.minY...max(visible.minY, visible.maxY - size))
        let window = NSPanel(contentRect: CGRect(x: x, y: y, width: size, height: size),
                             styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        window.title = titles.randomElement() ?? "RANS0M"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.hidesOnDeactivate = false
        window.ignoresMouseEvents = true
        window.backgroundColor = NSColor(red: 0.16, green: 0.0, blue: 0.0, alpha: 1)
        let imageView = NSImageView(frame: NSRect(origin: .zero, size: CGSize(width: size, height: size)))
        if let chosen = imageNames.randomElement() {
            let ext = chosen == "glitch2" ? "jpeg" : "jpg"
            let finalExt = ["idiot", "tauntface", "tauntflower"].contains(chosen) ? "png" : ext
            if let path = Bundle.main.path(forResource: chosen, ofType: finalExt) {
                imageView.image = NSImage(contentsOfFile: path)
            }
        }
        imageView.imageScaling = .scaleAxesIndependently
        window.contentView = imageView
        window.orderFrontRegardless()
        windows.append(window)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 4...9)) { [weak self, weak window] in
            guard let window else { return }
            window.close()
            self?.windows.removeAll(where: { $0 === window })
        }
    }

    func closeAll() {
        windows.forEach { $0.close() }
        windows.removeAll()
    }
}
