import Foundation

struct WarehouseTaskDTO: Decodable, Equatable {
    let id: String
    let orgId: String?
    let facilityId: String?
    let taskType: String
    let status: String
    let sku: String?
    let description: String?
    let quantity: Double?
    let uom: String?
    let fromLocationCode: String?
    let toLocationCode: String?
    let inboundShipmentId: String?
    let receivingEventId: String?
    let priority: Int?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case facilityId = "facility_id"
        case taskType = "task_type"
        case status
        case sku
        case description
        case quantity
        case uom
        case fromLocationCode = "from_location_code"
        case toLocationCode = "to_location_code"
        case inboundShipmentId = "inbound_shipment_id"
        case receivingEventId = "receiving_event_id"
        case priority
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct WarehouseTasksListResponse: Decodable {
    let mode: String
    let message: String?
    let items: [WarehouseTaskDTO]
    let pagination: APIPaginationDTO
}

struct WarehouseTaskDetailResponse: Decodable {
    let mode: String
    let message: String?
    let item: WarehouseTaskDTO
}

struct PutawayTaskItem: Identifiable, Equatable {
    let id: String
    let sku: String
    let description: String
    let quantity: Double
    let uom: String
    let status: String
    let fromLocationCode: String
    let toLocationCode: String
    let inboundShipmentId: String?
    let createdAt: Date?

    var statusDisplay: String {
        status.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var routeLabel: String {
        if fromLocationCode.isEmpty && toLocationCode.isEmpty { return "—" }
        if fromLocationCode.isEmpty { return toLocationCode }
        if toLocationCode.isEmpty { return fromLocationCode }
        return "\(fromLocationCode) → \(toLocationCode)"
    }
}

enum PutawayTaskStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case assigned
    case inProgress = "in_progress"
    case completed
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .assigned: return "Assigned"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    var apiStatus: String? {
        self == .all ? nil : rawValue
    }
}

enum WarehouseTaskAPIMapping {
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

    static func mapTask(_ dto: WarehouseTaskDTO) -> PutawayTaskItem {
        PutawayTaskItem(
            id: dto.id,
            sku: dto.sku ?? "—",
            description: dto.description ?? "Putaway task",
            quantity: dto.quantity ?? 0,
            uom: dto.uom ?? "ea",
            status: dto.status,
            fromLocationCode: dto.fromLocationCode ?? "—",
            toLocationCode: dto.toLocationCode ?? "—",
            inboundShipmentId: dto.inboundShipmentId,
            createdAt: parseDate(dto.createdAt)
        )
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return isoFormatter.date(from: raw) ?? isoFormatterNoFraction.date(from: raw)
    }
}
