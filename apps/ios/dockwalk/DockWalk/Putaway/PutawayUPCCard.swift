import Foundation

/// Where a putaway inventory card was resolved from.
enum PutawayCardSource: String, Codable, Equatable {
    case receiveSession
    case catalog
    case api
}

/// One received inventory card (UPC) being moved into storage.
struct PutawayUPCCard: Identifiable, Equatable, Hashable {
    let id: String
    var upc: String
    var sku: String
    var itemName: String
    var partDescription: String
    var quantity: Double
    var quantityDisplay: String
    var uom: String
    var fromLocationCode: String
    var toLocationCode: String
    var inboundShipmentId: String?
    var status: PutawayTaskStatus
    var source: PutawayCardSource
    var createdAt: Date?
    /// When `source == .api`, id matches server task id.
    var apiTaskId: String?

    var description: String {
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        let part = partDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return part.isEmpty ? "Putaway" : part
    }

    var routeLabel: String {
        if fromLocationCode.isEmpty && toLocationCode.isEmpty { return "—" }
        if fromLocationCode.isEmpty { return toLocationCode }
        if toLocationCode.isEmpty { return "\(fromLocationCode) → scan bin" }
        return "\(fromLocationCode) → \(toLocationCode)"
    }

    var secondarySKULabel: String? {
        let trimmed = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.compare(upc, options: .caseInsensitive) != .orderedSame else {
            return nil
        }
        return "SKU \(trimmed)"
    }

    var serverTaskId: String? {
        switch source {
        case .api: return apiTaskId ?? id
        case .receiveSession, .catalog: return apiTaskId
        }
    }

    static func from(receive draft: ReceiveInventoryDraft, shipmentId: String?) -> PutawayUPCCard? {
        let trimmedUPC = draft.upc.trimmingCharacters(in: .whitespacesAndNewlines)
        guard draft.isSaved, !trimmedUPC.isEmpty else { return nil }
        return PutawayUPCCard(
            id: draft.id,
            upc: trimmedUPC,
            sku: draft.sku.trimmingCharacters(in: .whitespacesAndNewlines),
            itemName: draft.itemName,
            partDescription: draft.partDescription,
            quantity: Double(draft.committedQuantity),
            quantityDisplay: draft.quantityDisplay,
            uom: "EA",
            fromLocationCode: draft.location,
            toLocationCode: "",
            inboundShipmentId: shipmentId,
            status: .pending,
            source: .receiveSession,
            createdAt: nil,
            apiTaskId: nil
        )
    }

    static func from(catalog item: InventoryItem, shipmentId: String? = nil) -> PutawayUPCCard? {
        let trimmedUPC = (item.upc ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUPC.isEmpty else { return nil }
        return PutawayUPCCard(
            id: "cat-\(item.id)",
            upc: trimmedUPC,
            sku: item.sku,
            itemName: item.itemName,
            partDescription: item.partDescription ?? "",
            quantity: Double(item.quantity),
            quantityDisplay: "\(item.quantity) ea",
            uom: "EA",
            fromLocationCode: item.location,
            toLocationCode: "",
            inboundShipmentId: shipmentId,
            status: .pending,
            source: .catalog,
            createdAt: nil,
            apiTaskId: nil
        )
    }
}

/// Legacy name used across putaway views — one card per UPC line.
typealias PutawayTaskItem = PutawayUPCCard
