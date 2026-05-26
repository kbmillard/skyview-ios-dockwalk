import Foundation

struct FacilityConfigResponse: Codable, Equatable {
    let facilityId: String
    let facilityName: String?
    let receive: FacilityReceiveConfig?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case facilityId = "facility_id"
        case facilityName = "facility_name"
        case receive
        case updatedAt = "updated_at"
    }
}

struct FacilityReceiveConfig: Codable, Equatable {
    let defaultStagingLocationCode: String?
    let stagingDisplayName: String?

    enum CodingKeys: String, CodingKey {
        case defaultStagingLocationCode = "default_staging_location_code"
        case stagingDisplayName = "staging_display_name"
    }
}

struct FacilityLocationsResponse: Codable, Equatable {
    let items: [FacilityLocationDTO]
    let pagination: FacilityPagination?
}

struct FacilityLocationDTO: Codable, Equatable {
    let code: String
    let zone: String?
    let type: String?
}

struct FacilityPagination: Codable, Equatable {
    let offset: Int
    let limit: Int
    let total: Int
}

struct FacilityLocationLookupResponse: Codable, Equatable {
    let code: String
    let valid: Bool?
}

struct CatalogSearchResponse: Codable, Equatable {
    let query: String?
    let items: [CatalogItemDTO]
}

struct CatalogLookupResponse: Codable, Equatable {
    let item: CatalogItemDTO?
}

struct CatalogItemDTO: Codable, Equatable {
    let sku: String?
    let upc: String?
    let itemName: String?
    let defaultUom: String?
    let casesPerCase: Int?

    enum CodingKeys: String, CodingKey {
        case sku, upc
        case itemName = "item_name"
        case defaultUom = "default_uom"
        case casesPerCase = "cases_per_case"
    }
}

struct InboundFinalizeRequest: Codable, Equatable {
    let idempotencyKey: String
    let facilityId: String
    let lines: [InboundFinalizeLine]

    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case facilityId = "facility_id"
        case lines
    }
}

struct InboundFinalizeLine: Codable, Equatable {
    let clientLineId: String
    let upc: String
    let sku: String?
    let isUnregisteredUPC: Bool
    let cases: Int?
    let eachesPerCase: Int?
    let locationCode: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case clientLineId = "client_line_id"
        case upc, sku
        case isUnregisteredUPC = "is_unregistered_upc"
        case cases
        case eachesPerCase = "eaches_per_case"
        case locationCode = "location_code"
        case status
    }
}

struct InventoryMovementRequest: Codable, Equatable {
    let idempotencyKey: String
    let facilityId: String
    let movementType: String
    let upc: String
    let fromLocationCode: String
    let toLocationCode: String
    let quantity: Double
    let uom: String
    let inboundLoadId: String?
    let clientLineId: String

    enum CodingKeys: String, CodingKey {
        case idempotencyKey = "idempotency_key"
        case facilityId = "facility_id"
        case movementType = "movement_type"
        case upc
        case fromLocationCode = "from_location_code"
        case toLocationCode = "to_location_code"
        case quantity, uom
        case inboundLoadId = "inbound_load_id"
        case clientLineId = "client_line_id"
    }
}

struct EmptyAPIResponse: Decodable, Equatable {}

enum LocationsSyncPhase: Equatable {
    case idle
    case syncing
    case ready
    case failed(String)
}
