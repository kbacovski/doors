import Foundation

struct Coin: Identifiable {
    let id = UUID()
    let value: Int
    let drawer: Int
    let crucifix: Bool
}

@main
struct CoinStoreTest {
    static func main() throws {
        let folder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("work/mac-port/build/RANS0M-test-\(UUID().uuidString)", isDirectory: true)
        precondition(CoinStore.isAllowedRoot(folder), "Run this test from a workspace inside your home folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let documents = folder.appendingPathComponent("Documents", isDirectory: true)
        let downloads = folder.appendingPathComponent("Downloads", isDirectory: true)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: false)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: false)

        let store = CoinStore()
        let tutorial = Coin(value: 10, drawer: 0, crucifix: false)
        let coin = Coin(value: 50, drawer: 0, crucifix: false)
        let crucifix = Coin(value: 0, drawer: 0, crucifix: true)
        let round = [tutorial, coin, crucifix] + (0..<9).map { _ in Coin(value: 100, drawer: 0, crucifix: false) }
        let placed = store.scatter(round, in: [documents, downloads])
        precondition(placed.count == round.count, "Markers were not created")

        let subfolders = try [documents, downloads].flatMap {
            try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)
        }
        precondition(subfolders.count == 2, "Each selected location needs a game-owned folder")
        let drawers = try subfolders.flatMap {
            try FileManager.default.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil)
                .filter { $0.hasDirectoryPath }
        }
        precondition(drawers.count == 12, "Each selected location needs six colorful drawers")
        let first = subfolders.first { $0.deletingLastPathComponent() == documents }!
            .appendingPathComponent("Монеты 01", isDirectory: true)
        let tutorialMarkers = try FileManager.default.contentsOfDirectory(at: first, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.hasPrefix("gold") || $0.pathExtension == "crucifix" }
        precondition(tutorialMarkers.count == 1 && tutorialMarkers[0].pathExtension == "gold1",
                     "The first folder must contain exactly one 10G coin")
        let decoys = try drawers.filter { folder in
            try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                .allSatisfy { !$0.pathExtension.hasPrefix("gold") && $0.pathExtension != "crucifix" }
        }
        precondition(decoys.count >= 4, "The round needs empty decoy folders")
        let files = [documents, downloads].flatMap { root -> [URL] in
            guard let iterator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil) else { return [] }
            return iterator.compactMap { $0 as? URL }.filter { $0.pathExtension.hasPrefix("gold") || $0.pathExtension == "crucifix" }
        }
        precondition(files.count == round.count)
        let goldFile = files.first { $0.pathExtension == "gold2" }!
        precondition(store.coinID(at: goldFile) == coin.id)
        precondition(store.consume(coin.id), "A valid coin could not be consumed")
        precondition(!FileManager.default.fileExists(atPath: goldFile.path))
        precondition(!store.consume(coin.id), "A coin was consumed twice")

        let crucifixFile = files.first { $0.pathExtension == "crucifix" }!
        try Data("user changed this file".utf8).write(to: crucifixFile)
        store.cleanup()
        precondition(FileManager.default.fileExists(atPath: crucifixFile.path),
                     "Cleanup deleted a file that no longer matched its marker")
        let defaultPlaced = store.scatter([tutorial, coin, crucifix], in: [])
        precondition(defaultPlaced.count == 3)
        let defaultRoot = store.currentRoot!
        let defaultDrawers = try FileManager.default.contentsOfDirectory(at: defaultRoot, includingPropertiesForKeys: nil)
            .filter { $0.hasDirectoryPath }
        precondition(defaultDrawers.count == 30, "The default round needs thirty drawers")
        store.cleanup()
        print("Colorful drawers, tutorial coin, decoys, payment, and safe cleanup passed")
    }
}
