import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Inbound lines (GET …/shipments/:id/lines)

struct InboundLinesResponse: Decodable, Equatable {
    let mode: String
    let message: String?
    let shipmentId: String?
    let orgId: String?
    let items: [InboundLineDTO]

    enum CodingKeys: String, CodingKey {
        case mode
        case message
        case shipmentId = "shipment_id"
        case orgId = "org_id"
        case items
    }
}

struct InboundLineDTO: Decodable, Equatable {
    let id: String
    let inboundShipmentId: String?
    let inventoryItemId: String?
    let sku: String?
    let description: String?
    let expectedQty: Double?
    let receivedQty: Double?
    let quantityDamaged: Double?
    let uom: String?
    let status: String?
    let metadata: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id
        case inboundShipmentId = "inbound_shipment_id"
        case legacyShipmentId = "shipment_id"
        case inventoryItemId = "inventory_item_id"
        case sku
        case description
        case quantityExpected = "quantity_expected"
        case legacyExpectedQty = "expected_qty"
        case quantityReceived = "quantity_received"
        case legacyReceivedQty = "received_qty"
        case quantityDamaged = "quantity_damaged"
        case uom
        case status
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        inboundShipmentId =
            try container.decodeIfPresent(String.self, forKey: .inboundShipmentId)
            ?? container.decodeIfPresent(String.self, forKey: .legacyShipmentId)
        inventoryItemId = try container.decodeIfPresent(String.self, forKey: .inventoryItemId)
        sku = try container.decodeIfPresent(String.self, forKey: .sku)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        expectedQty =
            try container.decodeIfPresent(Double.self, forKey: .quantityExpected)
            ?? container.decodeIfPresent(Double.self, forKey: .legacyExpectedQty)
        receivedQty =
            try container.decodeIfPresent(Double.self, forKey: .quantityReceived)
            ?? container.decodeIfPresent(Double.self, forKey: .legacyReceivedQty)
        quantityDamaged = try container.decodeIfPresent(Double.self, forKey: .quantityDamaged)
        uom = try container.decodeIfPresent(String.self, forKey: .uom)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        metadata = try container.decodeIfPresent([String: JSONValue].self, forKey: .metadata)
    }
}

// MARK: - Receiving events (POST /api/inbound/receiving-events)

struct ReceivingEventLineRequest: Codable, Equatable {
    var inboundLineId: String?
    var inventoryItemId: String?
    var sku: String?
    var quantityExpected: Double?
    var quantityReceived: Double
    var quantityDamaged: Double?
    var quantityShort: Double?
    var conditionStatus: String?
    var rawBarcode: String?
    var metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case inboundLineId = "inbound_line_id"
        case inventoryItemId = "inventory_item_id"
        case sku
        case quantityExpected = "quantity_expected"
        case quantityReceived = "quantity_received"
        case quantityDamaged = "quantity_damaged"
        case quantityShort = "quantity_short"
        case conditionStatus = "condition_status"
        case rawBarcode = "raw_barcode"
        case metadata
    }
}

struct CreateReceivingEventRequest: Codable, Equatable {
    let orgId: String
    let facilityId: String
    var appointmentId: String?
    var inboundShipmentId: String?
    let eventType: String
    var source: String?
    var deviceId: String?
    var performedBy: String?
    let idempotencyKey: String
    var notes: String?
    var lines: [ReceivingEventLineRequest]

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case facilityId = "facility_id"
        case appointmentId = "appointment_id"
        case inboundShipmentId = "inbound_shipment_id"
        case eventType = "event_type"
        case source
        case deviceId = "device_id"
        case performedBy = "performed_by"
        case idempotencyKey = "idempotency_key"
        case notes
        case lines
    }

    static func makeIdempotencyKey() -> String {
        "ios-\(UUID().uuidString.lowercased())"
    }
}

struct ReceivingEventItemDTO: Decodable, Equatable {
    let id: String
    let orgId: String?
    let status: String?
    let eventType: String?
    let lineCount: Int?
    let idempotencyKey: String?

    enum CodingKeys: String, CodingKey {
        case id
        case orgId = "org_id"
        case status
        case eventType = "event_type"
        case lineCount = "line_count"
        case idempotencyKey = "idempotency_key"
    }
}

struct ReceivingEventResponse: Decodable, Equatable {
    let mode: String
    let idempotent: Bool?
    let item: ReceivingEventItemDTO?
    let message: String?

    var isIdempotentReplay: Bool { idempotent == true }
    var isSuccess: Bool { item != nil }
}

struct APIErrorResponse: Decodable, Equatable {
    struct ErrorBody: Decodable, Equatable {
        let code: String
        let message: String
    }

    let error: ErrorBody
    let requestId: String?
}

enum ReceivingEventBuilder {
    static func buildSingleLineReceive(
        environment: AppEnvironment,
        appointmentId: String?,
        shipmentId: String,
        line: InboundLineItem,
        quantity: Double = 1,
        idempotencyKey: String = CreateReceivingEventRequest.makeIdempotencyKey()
    ) -> CreateReceivingEventRequest {
        let sku = line.sku.isEmpty ? nil : line.sku
        return CreateReceivingEventRequest(
            orgId: environment.orgId,
            facilityId: environment.facilityId,
            appointmentId: appointmentId,
            inboundShipmentId: shipmentId,
            eventType: "receive_scan",
            source: "device",
            deviceId: deviceId,
            performedBy: "dockwalk-ios",
            idempotencyKey: idempotencyKey,
            lines: [
                ReceivingEventLineRequest(
                    inboundLineId: line.id,
                    inventoryItemId: nil,
                    sku: sku,
                    quantityExpected: line.expectedQty,
                    quantityReceived: quantity,
                    quantityDamaged: 0,
                    quantityShort: 0,
                    conditionStatus: "good",
                    rawBarcode: sku,
                    metadata: ["source": "manual_receive"]
                ),
            ]
        )
    }

    static func buildRequest(
        environment: AppEnvironment,
        appointmentId: String?,
        shipmentId: String,
        lines: [InboundLineItem],
        idempotencyKey: String = CreateReceivingEventRequest.makeIdempotencyKey()
    ) -> CreateReceivingEventRequest {
        let eventLines = lines.compactMap { line -> ReceivingEventLineRequest? in
            guard line.receiveNow > 0 else { return nil }
            let sku = line.sku.isEmpty ? nil : line.sku
            return ReceivingEventLineRequest(
                inboundLineId: line.id,
                inventoryItemId: nil,
                sku: sku,
                quantityExpected: line.expectedQty,
                quantityReceived: line.receiveNow,
                quantityDamaged: 0,
                quantityShort: 0,
                conditionStatus: "good",
                rawBarcode: sku,
                metadata: ["source": "manual_receive"]
            )
        }
        return CreateReceivingEventRequest(
            orgId: environment.orgId,
            facilityId: environment.facilityId,
            appointmentId: appointmentId,
            inboundShipmentId: shipmentId,
            eventType: "receive_scan",
            source: "device",
            deviceId: deviceId,
            performedBy: "dockwalk-ios",
            idempotencyKey: idempotencyKey,
            lines: eventLines
        )
    }

    static var deviceId: String {
        #if os(iOS)
        UIDevice.current.identifierForVendor?.uuidString ?? "dockwalk-ios"
        #else
        "dockwalk-ios"
        #endif
    }
}
