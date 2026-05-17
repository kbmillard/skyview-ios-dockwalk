import Foundation

struct APIListResponse<Item: Decodable>: Decodable {
    let mode: String
    let message: String?
    let items: [Item]
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
