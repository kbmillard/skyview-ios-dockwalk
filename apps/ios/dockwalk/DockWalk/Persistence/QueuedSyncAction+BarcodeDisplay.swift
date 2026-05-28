import Foundation

extension QueuedSyncAction {

    /// Best floor identifier for this queued action (UPC / barcode first).
    var primaryBarcode: String? {
        switch kind {
        case OfflineSyncStore.inventoryMovementKind:
            let code = movementPayload?.upc.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return code.isEmpty ? nil : code

        case OfflineSyncStore.finalizeLoadKind:
            guard let lines = finalizePayload?.lines, !lines.isEmpty else { return nil }
            if lines.count == 1 {
                let upc = lines[0].upc.trimmingCharacters(in: .whitespacesAndNewlines)
                return upc.isEmpty ? nil : upc
            }
            return "\(lines.count) lines"

        case OfflineSyncStore.receivingEventKind:
            guard let lines = receivingEventPayload?.lines, !lines.isEmpty else { return nil }
            for line in lines {
                if let raw = line.rawBarcode?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
                    return raw
                }
                if let sku = line.sku?.trimmingCharacters(in: .whitespacesAndNewlines), !sku.isEmpty {
                    return sku
                }
            }
            return nil

        case OfflineSyncStore.taskActionKind:
            return taskActionSKUFromSummary

        default:
            return nil
        }
    }

    var kindDisplayName: String {
        switch kind {
        case OfflineSyncStore.receivingEventKind: return "Receiving"
        case OfflineSyncStore.finalizeLoadKind: return "Finalize"
        case OfflineSyncStore.inventoryMovementKind: return "Putaway"
        case OfflineSyncStore.taskActionKind: return "Task"
        default: return kind
        }
    }

    private var taskActionSKUFromSummary: String? {
        guard kind == OfflineSyncStore.taskActionKind else { return nil }
        let parts = summary.split(separator: " ")
        guard let last = parts.last, !last.isEmpty else { return nil }
        return String(last)
    }
}
