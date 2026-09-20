import AppKit
import Foundation

/// Owns only the harmless marker files created by a RANS0M round.
/// The manifest lets a later launch clean up after a crash without touching other files.
final class CoinStore {
    private struct Payload: Codable, Equatable {
        let id: UUID
        let value: Int
        let crucifix: Bool
        let signature: String

        init(id: UUID, value: Int, crucifix: Bool) {
            self.id = id
            self.value = value
            self.crucifix = crucifix
            signature = "RANS0M_MAC_MARKER_V2"
        }
    }

    private struct Record: Codable {
        let id: UUID
        let path: String
        let value: Int
        let crucifix: Bool
    }

    private struct Manifest: Codable {
        let records: [Record]
        let ownedFolders: [String]
    }

    private let fileManager = FileManager.default
    private let supportRoot: URL
    private let manifestURL: URL
    private var records: [UUID: Record] = [:]
    private var ownedFolders: [String] = []
    private(set) var currentRoots: [URL] = []
    var currentRoot: URL? { currentRoots.first }

    static func isAllowedRoot(_ url: URL) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.resolvingSymlinksInPath().standardizedFileURL.path
        let chosen = url.resolvingSymlinksInPath().standardizedFileURL.path
        return chosen == home || chosen.hasPrefix(home + "/")
    }

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        supportRoot = base.appendingPathComponent("RANS0M Mac", isDirectory: true)
        manifestURL = supportRoot.appendingPathComponent("marker-manifest.json")
        try? fileManager.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: manifestURL) {
            if let saved = try? JSONDecoder().decode(Manifest.self, from: data) {
                records = Dictionary(uniqueKeysWithValues: saved.records.map { ($0.id, $0) })
                ownedFolders = saved.ownedFolders
            } else if let legacy = try? JSONDecoder().decode([Record].self, from: data) {
                records = Dictionary(uniqueKeysWithValues: legacy.map { ($0.id, $0) })
            }
        }
        cleanup()
    }

    @discardableResult
    func scatter(_ coins: [Coin], in selectedFolders: [URL]) -> [Coin] {
        cleanup()
        var destinations: [URL] = []
        var entryDrawers: [URL] = []
        let roundID = String(UUID().uuidString.prefix(8))
        if !selectedFolders.isEmpty {
            for selected in selectedFolders.prefix(8) {
                let root = selected.standardizedFileURL
                guard Self.isAllowedRoot(root), isRealDirectory(root),
                      fileManager.isWritableFile(atPath: root.path) else { continue }
                let gameFolder = root.appendingPathComponent("RANS0M-COINS-\(roundID)", isDirectory: true)
                guard createOwnedFolder(gameFolder, colorIndex: currentRoots.count) else { continue }
                // Finder opens the game-owned folder, showing Drawer 01 first.
                currentRoots.append(gameFolder)
                for number in 1...6 {
                    let drawer = gameFolder.appendingPathComponent(String(format: "Монеты %02d", number), isDirectory: true)
                    if createOwnedFolder(drawer, colorIndex: destinations.count) {
                        destinations.append(drawer)
                        if number == 1 { entryDrawers.append(drawer) }
                    }
                }
            }
        } else {
            let round = supportRoot.appendingPathComponent("Rounds", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            if createOwnedFolder(round, intermediate: true) {
                currentRoots = [round]
                for number in 1...30 {
                    let drawer = round.appendingPathComponent(String(format: "Drawer %02d", number), isDirectory: true)
                    if createOwnedFolder(drawer, colorIndex: number - 1) {
                        destinations.append(drawer)
                        if number == 1 { entryDrawers.append(drawer) }
                    }
                }
            }
        }

        guard !destinations.isEmpty else { return [] }
        // Drawer 01 is a one-coin introduction; never add a second marker to it.
        // Most other drawers are empty decoys, but each selected location has a clue.
        let tutorial = entryDrawers.first ?? destinations[0]
        let furtherEntries = Array(entryDrawers.dropFirst())
        let candidates = destinations.filter { $0 != tutorial && !furtherEntries.contains($0) }
        let populated = Array(candidates.shuffled().prefix(max(1, candidates.count / 3)))
        var created: [Coin] = []
        for (index, coin) in coins.enumerated() {
            let destination: URL
            if index == 0 { destination = tutorial }
            else if index <= furtherEntries.count { destination = furtherEntries[index - 1] }
            else { destination = populated.randomElement() ?? furtherEntries.randomElement() ?? tutorial }
            let ext = coin.crucifix ? "crucifix" : "gold\(goldType(for: coin.value))"
            let file = destination.appendingPathComponent(coin.id.uuidString.lowercased()).appendingPathExtension(ext)
            let payload = Payload(id: coin.id, value: coin.value, crucifix: coin.crucifix)
            guard !fileManager.fileExists(atPath: file.path),
                  let data = try? JSONEncoder().encode(payload),
                  (try? data.write(to: file, options: .atomic)) != nil else { continue }
            records[coin.id] = Record(id: coin.id, path: file.path, value: coin.value, crucifix: coin.crucifix)
            persist()
            let iconName = coin.crucifix ? "crucifix" : "Gold"
            let iconExtension = coin.crucifix ? "ico" : "png"
            if let path = Bundle.main.path(forResource: iconName, ofType: iconExtension),
               let icon = NSImage(contentsOfFile: path) {
                _ = NSWorkspace.shared.setIcon(icon, forFile: file.path, options: [])
            }
            created.append(coin)
        }
        return created
    }

    func coinID(at url: URL) -> UUID? {
        let path = url.standardizedFileURL.path
        return records.values.first(where: { URL(fileURLWithPath: $0.path).standardizedFileURL.path == path })?.id
    }

    func consume(_ id: UUID) -> Bool {
        guard let record = records[id], markerMatches(record) else { return false }
        do {
            try fileManager.removeItem(atPath: record.path)
            records.removeValue(forKey: id)
            persist()
            return true
        } catch {
            return false
        }
    }

    func cleanup() {
        for record in records.values where markerMatches(record) {
            try? fileManager.removeItem(atPath: record.path)
        }
        records.removeAll()
        for folder in ownedFolders.sorted(by: { $0.count > $1.count }) {
            removeIfEmptyOrOnlyFinderMetadata(URL(fileURLWithPath: folder, isDirectory: true))
        }
        ownedFolders.removeAll()
        persist()
        removeEmptyOwnedDrawers()
        currentRoots = []
    }

    func openInFinder(all: Bool = true) {
        let roots = all ? currentRoots : Array(currentRoots.prefix(1))
        for root in roots { NSWorkspace.shared.open(root) }
    }

    private func markerMatches(_ record: Record) -> Bool {
        let url = URL(fileURLWithPath: record.path)
        guard let attributes = try? fileManager.attributesOfItem(atPath: record.path),
              attributes[.type] as? FileAttributeType == .typeRegular,
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return false }
        return payload.signature == "RANS0M_MAC_MARKER_V2"
            && payload.id == record.id && payload.value == record.value
            && payload.crucifix == record.crucifix
    }

    private func persist() {
        let data = try? JSONEncoder().encode(Manifest(records: Array(records.values), ownedFolders: ownedFolders))
        if let data { try? data.write(to: manifestURL, options: .atomic) }
    }

    private func goldType(for value: Int) -> Int {
        switch value {
        case 10: 1
        case 50: 2
        case 100: 3
        case 150: 4
        case 200: 5
        default: 6
        }
    }

    private func createOwnedFolder(_ url: URL, intermediate: Bool = false, colorIndex: Int = 0) -> Bool {
        guard !fileManager.fileExists(atPath: url.path) else { return false }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: intermediate)
            ownedFolders.append(url.path)
            persist()
            _ = NSWorkspace.shared.setIcon(folderIcon(colorIndex: colorIndex), forFile: url.path, options: [])
            return true
        } catch {
            return false
        }
    }

    private func folderIcon(colorIndex: Int) -> NSImage {
        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.97, 0.75, 0.16), // yellow
            (0.96, 0.39, 0.68), // pink
            (0.29, 0.80, 0.41), // green
            (0.91, 0.13, 0.17), // red
            (0.29, 0.63, 0.95), // blue
            (0.64, 0.38, 0.94)  // violet
        ]
        let (r, g, b) = colors[colorIndex % colors.count]
        return NSImage(size: NSSize(width: 128, height: 128), flipped: false) { _ in
            NSColor(red: r * 0.56, green: g * 0.56, blue: b * 0.56, alpha: 1).setFill()
            NSBezierPath(roundedRect: NSRect(x: 11, y: 72, width: 61, height: 33),
                         xRadius: 10, yRadius: 10).fill()
            NSColor(red: r, green: g, blue: b, alpha: 1).setFill()
            NSBezierPath(roundedRect: NSRect(x: 7, y: 16, width: 114, height: 75),
                         xRadius: 14, yRadius: 14).fill()
            NSColor(red: min(1, r + 0.16), green: min(1, g + 0.16), blue: min(1, b + 0.16), alpha: 0.8).setFill()
            NSBezierPath(roundedRect: NSRect(x: 12, y: 70, width: 104, height: 17),
                         xRadius: 7, yRadius: 7).fill()
            return true
        }
    }

    private func removeEmptyOwnedDrawers() {
        let rounds = supportRoot.appendingPathComponent("Rounds", isDirectory: true)
        guard let roundFolders = try? fileManager.contentsOfDirectory(at: rounds, includingPropertiesForKeys: nil) else { return }
        for round in roundFolders {
            guard isRealDirectory(round) else { continue }
            for index in 1...30 {
                let drawer = round.appendingPathComponent(String(format: "Drawer %02d", index), isDirectory: true)
                removeIfEmptyOrOnlyFinderMetadata(drawer)
            }
            // Folders from older releases used unpadded names.
            for index in 1...6 {
                removeIfEmptyOrOnlyFinderMetadata(round.appendingPathComponent("Drawer \(index)", isDirectory: true))
            }
            removeIfEmptyOrOnlyFinderMetadata(round)
        }
    }

    private func isRealDirectory(_ url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) else { return false }
        return values.isDirectory == true && values.isSymbolicLink != true
    }

    private func removeIfEmptyOrOnlyFinderMetadata(_ folder: URL) {
        guard isRealDirectory(folder),
              let children = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return }
        guard children.allSatisfy({ [".DS_Store", "Icon\r"].contains($0.lastPathComponent) }) else { return }
        _ = NSWorkspace.shared.setIcon(nil, forFile: folder.path, options: [])
        for child in children { try? fileManager.removeItem(at: child) }
        try? fileManager.removeItem(at: folder)
    }
}
