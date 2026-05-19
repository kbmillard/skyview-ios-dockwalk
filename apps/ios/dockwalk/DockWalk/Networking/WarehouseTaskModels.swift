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

// NOTE: PutawayTaskItem, PutawayTaskStatusFilter, and PutawayAPIMapping 
// moved to /Putaway/PutawayModels.swift and /Putaway/PutawayAPIMapping.swift
// WarehouseTaskDTO remains here as it's a pure API contract type
