import Foundation

enum PutawayAPIMapping {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFormatterNoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Maps backend WarehouseTaskDTO to client PutawayTaskItem
    static func mapTask(_ dto: WarehouseTaskDTO) -> PutawayTaskItem {
        PutawayTaskItem(
            id: dto.id,
            sku: dto.sku ?? "—",
            description: dto.description ?? "Putaway task",
            quantity: dto.quantity ?? 0,
            uom: dto.uom ?? "ea",
            status: mapPutawayTaskStatus(dto.status),
            fromLocationCode: dto.fromLocationCode ?? "—",
            toLocationCode: dto.toLocationCode ?? "—",
            inboundShipmentId: dto.inboundShipmentId,
            createdAt: parseDate(dto.createdAt)
        )
    }
    
    /// Maps API status string to PutawayTaskStatus enum
    static func mapPutawayTaskStatus(_ raw: String?) -> PutawayTaskStatus {
        guard let raw = raw?.lowercased() else { return .pending }
        
        switch raw {
        case "pending": return .pending
        case "assigned": return .assigned
        case "in_progress": return .inProgress
        case "blocked": return .blocked
        case "completed": return .completed
        case "cancelled": return .cancelled
        default: return .pending
        }
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return isoFormatter.date(from: raw) ?? isoFormatterNoFraction.date(from: raw)
    }
}
