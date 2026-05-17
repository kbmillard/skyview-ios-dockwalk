import Foundation

struct QueuedSyncAction: Identifiable, Equatable, Codable {
    let id: UUID
    let kind: String
    let summary: String
    let createdAt: Date
    /// JSON-encoded `CreateReceivingEventRequest` when `kind == inbound.receiving_event`.
    var receivingEventPayload: CreateReceivingEventRequest?

    init(
        id: UUID = UUID(),
        kind: String,
        summary: String,
        createdAt: Date = .now,
        receivingEventPayload: CreateReceivingEventRequest? = nil
    ) {
        self.id = id
        self.kind = kind
        self.summary = summary
        self.createdAt = createdAt
        self.receivingEventPayload = receivingEventPayload
    }
}

enum SyncQueuePersistence {
    private static let fileName = "dockwalk_sync_queue.json"

    static func fileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = base.appendingPathComponent("DockWalk", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }

    static func load() -> [QueuedSyncAction] {
        let url = fileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([QueuedSyncAction].self, from: data)
        } catch {
            return []
        }
    }

    @discardableResult
    static func save(_ actions: [QueuedSyncAction]) -> Bool {
        do {
            let data = try JSONEncoder().encode(actions)
            try data.write(to: fileURL(), options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
