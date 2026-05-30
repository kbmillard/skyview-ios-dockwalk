import Foundation

struct APIListResponse<Item: Decodable>: Decodable {
    let mode: String
    let message: String?
    let items: [Item]
}

struct AppointmentItemResponse: Decodable {
    let mode: String
    let item: AppointmentDTO
}

struct AppointmentUpdateRequest: Codable, Equatable {
    var referenceNumber: String?
    var scheduledAt: String?
    var status: String?
    var notes: String?
    var metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case referenceNumber = "reference_number"
        case scheduledAt = "scheduled_at"
        case status
        case notes
        case metadata
    }
}

struct AppointmentDTO: Decodable {
    let id: String
    let orgId: String?
    let facilityId: String?
    let dockId: String?
    let carrierId: String?
    let referenceNumber: String?
    let status: String?
    let scheduledAt: String?
    let notes: String?
    let metadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case facilityId = "facility_id"
        case dockId = "dock_id"
        case carrierId = "carrier_id"
        case referenceNumber = "reference_number"
        case status
        case scheduledAt = "scheduled_at"
        case notes
        case metadata
    }
}

struct InboundShipmentDTO: Decodable {
    let id: String
    let orgId: String?
    let facilityId: String?
    let appointmentId: String?
    let referenceNumber: String?
    let status: String?
    let expectedAt: String?
    let receivedAt: String?
    let metadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case facilityId = "facility_id"
        case appointmentId = "appointment_id"
        case referenceNumber = "reference_number"
        case status
        case expectedAt = "expected_at"
        case receivedAt = "received_at"
        case metadata
    }
}

/// Loose JSON for API `metadata` blobs.
enum JSONValue: Decodable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        switch self {
        case .int(let value): return value
        case .double(let value): return Int(value)
        default: return nil
        }
    }
}

struct OutboundLineTransitionRequest: Codable, Equatable {
    let lineId: String
    var upc: String?
    let quantityLoaded: Double
    var allowOverscan: Bool?
    var action: String = "load_scan"

    enum CodingKeys: String, CodingKey {
        case lineId = "line_id"
        case upc
        case quantityLoaded = "quantity_loaded"
        case allowOverscan = "allow_overscan"
        case action
    }
}

struct OutboundOrderTransitionRequest: Codable, Equatable {
    let orgId: String
    let toStatus: String
    let idempotencyKey: String
    var facilityId: String?
    var deviceId: String?
    var notes: String?
    var metadata: [String: String]?
    var lineTransitions: [OutboundLineTransitionRequest]

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case toStatus = "to_status"
        case idempotencyKey = "idempotency_key"
        case facilityId = "facility_id"
        case deviceId = "device_id"
        case notes
        case metadata
        case lineTransitions = "line_transitions"
    }
}

struct OutboundOrdersResponse: Decodable, Equatable {
    let mode: String
    let message: String?
    let items: [OutboundOrderDTO]
}

struct OutboundOrderDetailResponse: Decodable, Equatable {
    let mode: String
    let message: String?
    let item: OutboundOrderDTO
}

struct OutboundOrderLinesResponse: Decodable, Equatable {
    let mode: String
    let message: String?
    let orderId: String?
    let items: [OutboundLineDTO]

    enum CodingKeys: String, CodingKey {
        case mode
        case message
        case orderId = "order_id"
        case items
    }
}

struct OutboundOrderDTO: Decodable, Equatable {
    let id: String
    let orgId: String?
    let facilityId: String?
    let orderNumber: String?
    let status: String?
    let requestedShipAt: String?
    let lineCount: Int?
    let stagedLineCount: Int?
    let loadedLineCount: Int?
    let cartonCount: Int?
    let metadata: [String: JSONValue]?
    let updatedAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case facilityId = "facility_id"
        case orderNumber = "order_number"
        case status
        case requestedShipAt = "requested_ship_at"
        case lineCount = "line_count"
        case stagedLineCount = "staged_line_count"
        case loadedLineCount = "loaded_line_count"
        case cartonCount = "carton_count"
        case metadata
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}

struct OutboundLineDTO: Decodable, Equatable {
    let id: String
    let orgId: String?
    let orderId: String?
    let lineNumber: Int?
    let sku: String?
    let upc: String?
    let orderedQty: Double?
    let loadedQty: Double?
    let pickedQty: Double?
    let uom: String?
    let status: String?
    let metadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case orderId = "order_id"
        case lineNumber = "line_number"
        case sku
        case upc
        case orderedQty = "ordered_qty"
        case loadedQty = "loaded_qty"
        case pickedQty = "picked_qty"
        case uom
        case status
        case metadata
    }
}

struct OutboundOrderTransitionResponse: Decodable, Equatable {
    let mode: String
    let idempotent: Bool?
    let item: OutboundOrderTransitionItem?
}

struct OutboundOrderTransitionItem: Decodable, Equatable {
    let orderId: String
    let fromStatus: String
    let toStatus: String
    let transitionedAt: String?
    let lineUpdates: [OutboundOrderTransitionLineUpdate]
    let order: OutboundOrderDTO?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case fromStatus = "from_status"
        case toStatus = "to_status"
        case transitionedAt = "transitioned_at"
        case lineUpdates = "line_updates"
        case order
    }
}

struct OutboundOrderTransitionLineUpdate: Decodable, Equatable {
    let lineId: String
    let sku: String
    let orderedQty: Double
    let loadedQty: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case lineId = "line_id"
        case sku
        case orderedQty = "ordered_qty"
        case loadedQty = "loaded_qty"
        case status
    }
}
