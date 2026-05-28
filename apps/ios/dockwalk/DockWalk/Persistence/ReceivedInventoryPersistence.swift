import Foundation

/// Persists receive-work drafts per load so tab switches and app restarts do not lose in-progress receiving.
enum ReceivedInventoryPersistence {
    private static let fileName = "dockwalk_received_inventory.json"

    static func fileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("DockWalk", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }

    static func load() -> [String: [ReceiveInventoryDraft]] {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [:] }
        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)
            return snapshot.receivedByLoadId
        } catch {
            return [:]
        }
    }

    @discardableResult
    static func save(_ receivedByLoadId: [String: [ReceiveInventoryDraft]]) -> Bool {
        do {
            let snapshot = Snapshot(receivedByLoadId: receivedByLoadId)
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: fileURL(), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private struct Snapshot: Codable {
        var receivedByLoadId: [String: [ReceiveInventoryDraft]]
    }
}
