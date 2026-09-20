import AppKit
import QuartzCore

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
    private var windows: [NSPanel] = []
    private let imageNames = ["glitch1", "glitch2", "glitch3", "glitch4", "glitch5", "idiot", "tauntface", "tauntflower"]
    private let messages = [
        ("RANS0M", "GIVE ME YOUR GOLD"),
        ("ERROR", "YOU ARE AN IDIOT"),
        ("SYSTEM ALERT", "I CAN SEE YOU"),
        ("PAYMENT REQUIRED", "TIME IS RUNNING OUT"),
        ("RANS0M", "THE DOORS ARE CLOSING"),
        ("WARNING", "YOU CANNOT HIDE"),
        ("ERROR 90", "FIND THE COINS"),
        ("UNKNOWN", "I AM STILL HERE")
    ]
    private let maxWindows = 18

    func spawn(count: Int) {
        for _ in 0..<count { spawnOne() }
    }

    private func spawnOne() {
        guard windows.count < maxWindows, let screen = NSScreen.screens.randomElement() else { return }
        let isMessage = Bool.random()
        let width = isMessage ? CGFloat.random(in: 225...330) : CGFloat.random(in: 155...255)
        let height = isMessage ? CGFloat.random(in: 110...155) : width
        let visible = screen.visibleFrame
        let x = CGFloat.random(in: visible.minX...max(visible.minX, visible.maxX - width))
        let y = CGFloat.random(in: visible.minY...max(visible.minY, visible.maxY - height))
        let window = NSPanel(contentRect: NSRect(x: x, y: y, width: width, height: height),
                             styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.hidesOnDeactivate = false
        window.ignoresMouseEvents = true
        window.isMovable = false
        window.isMovableByWindowBackground = false
        window.hasShadow = true
        window.backgroundColor = NSColor(red: 0.09, green: 0.01, blue: 0.01, alpha: 1)
        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        content.wantsLayer = true
        content.layer?.borderColor = NSColor(red: 0.92, green: 0.08, blue: 0.08, alpha: 1).cgColor
        content.layer?.borderWidth = 2
        if isMessage {
            let (title, message) = messages.randomElement() ?? messages[0]
            let heading = NSTextField(labelWithString: title)
            heading.frame = NSRect(x: 15, y: height - 35, width: width - 30, height: 20)
            heading.font = .monospacedSystemFont(ofSize: 13, weight: .heavy)
            heading.textColor = .white
            content.addSubview(heading)

            let divider = NSView(frame: NSRect(x: 0, y: height - 44, width: width, height: 2))
            divider.wantsLayer = true
            divider.layer?.backgroundColor = NSColor.systemRed.cgColor
            content.addSubview(divider)

            let warning = NSTextField(wrappingLabelWithString: message)
            warning.frame = NSRect(x: 15, y: 16, width: width - 30, height: height - 72)
            warning.font = .monospacedSystemFont(ofSize: 20, weight: .black)
            warning.textColor = NSColor(red: 1, green: 0.25, blue: 0.21, alpha: 1)
            warning.alignment = .center
            content.addSubview(warning)
        } else {
            let imageView = NSImageView(frame: content.bounds.insetBy(dx: 2, dy: 2))
            if let chosen = imageNames.randomElement() {
                let ext = chosen == "glitch2" ? "jpeg" : (["idiot", "tauntface", "tauntflower"].contains(chosen) ? "png" : "jpg")
                if let path = Bundle.main.path(forResource: chosen, ofType: ext) {
                    imageView.image = NSImage(contentsOfFile: path)
                }
            }
            imageView.imageScaling = .scaleAxesIndependently
            content.addSubview(imageView)
        }
        window.contentView = content
        window.orderFrontRegardless()
        windows.append(window)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3.5...7.0)) { [weak self, weak window] in
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

/// A temporary, click-through overlay above desktop icons but below app windows.
/// It does not edit wallpaper, Dock items, app bundles, or Finder icons.
final class DesktopVeilManager {
    private var windows: [NSPanel] = []

    func start() {
        stop()
        for screen in NSScreen.screens {
            let window = NSPanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = true
            window.hidesOnDeactivate = false
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            let view = NSView(frame: NSRect(origin: .zero, size: screen.frame.size))
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor(red: 0.78, green: 0, blue: 0, alpha: 1).cgColor
            view.layer?.opacity = 0.08
            let breath = CABasicAnimation(keyPath: "opacity")
            breath.fromValue = 0.08
            breath.toValue = 0.30
            breath.duration = 2.8
            breath.autoreverses = true
            breath.repeatCount = .infinity
            breath.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            view.layer?.add(breath, forKey: "redVeilBreath")
            window.contentView = view
            window.orderFrontRegardless()
            windows.append(window)
        }
    }

    func stop() {
        windows.forEach {
            $0.contentView?.layer?.removeAllAnimations()
            $0.close()
        }
        windows.removeAll()
    }
}
