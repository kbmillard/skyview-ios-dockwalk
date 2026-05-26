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

    /// Maps backend WarehouseTaskDTO to a UPC-first putaway card.
    static func mapCard(_ dto: WarehouseTaskDTO) -> PutawayUPCCard {
        let upc = extractUPC(from: dto.notes) ?? ""
        let sku = (dto.sku ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedUPC = upc.isEmpty ? sku : upc

        return PutawayUPCCard(
            id: dto.id,
            upc: resolvedUPC.isEmpty ? "—" : resolvedUPC,
            sku: sku,
            itemName: dto.description ?? "Putaway",
            partDescription: "",
            quantity: dto.quantity ?? 0,
            quantityDisplay: formatQuantityDisplay(dto.quantity, uom: dto.uom),
            uom: dto.uom ?? "ea",
            fromLocationCode: dto.fromLocationCode ?? "",
            toLocationCode: dto.toLocationCode ?? "",
            inboundShipmentId: dto.inboundShipmentId,
            status: mapPutawayTaskStatus(dto.status),
            source: .api,
            createdAt: parseDate(dto.createdAt),
            apiTaskId: dto.id
        )
    }

    static func mapTask(_ dto: WarehouseTaskDTO) -> PutawayUPCCard {
        mapCard(dto)
    }

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

    /// Interim: parse `UPC:012345678901` from task notes until API has a dedicated column.
    static func extractUPC(from notes: String?) -> String? {
        guard let notes, !notes.isEmpty else { return nil }
        let upper = notes.uppercased()
        guard let marker = upper.range(of: "UPC:") else { return nil }
        let after = notes[marker.upperBound...]
        let token = after.split(whereSeparator: { $0.isWhitespace || $0 == "|" }).first
        let trimmed = token.map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        return trimmed?.isEmpty == false ? trimmed : nil
    }

    private static func formatQuantityDisplay(_ qty: Double?, uom: String?) -> String {
        let value = qty ?? 0
        let unit = (uom ?? "ea").uppercased()
        let text = value == floor(value) ? String(Int(value)) : String(value)
        return "\(text) \(unit)"
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return isoFormatter.date(from: raw) ?? isoFormatterNoFraction.date(from: raw)
    }
}
