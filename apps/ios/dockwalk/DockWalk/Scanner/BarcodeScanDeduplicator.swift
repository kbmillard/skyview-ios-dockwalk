import Foundation

/// Suppresses repeated callbacks for the same scanned value within a cooldown window.
struct BarcodeScanDeduplicator {
    let cooldown: TimeInterval

    private var lastValue: String?
    private var lastAcceptedAt: Date?

    init(cooldown: TimeInterval = 2.0) {
        self.cooldown = cooldown
    }

    mutating func shouldAccept(value: String, now: Date = .now) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if let lastValue,
           lastValue == trimmed,
           let lastAcceptedAt,
           now.timeIntervalSince(lastAcceptedAt) < cooldown {
            return false
        }

        lastValue = trimmed
        lastAcceptedAt = now
        return true
    }

    mutating func reset() {
        lastValue = nil
        lastAcceptedAt = nil
    }
}
