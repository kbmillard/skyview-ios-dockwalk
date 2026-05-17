import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct InboundLineDTO: Decodable {
    let id: String
    let shipmentId: String?
    let lineNumber: Int?
    let sku: String?
    let description: String?
    let expectedQty: Double?
    let receivedQty: Double?
    let uom: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId = "shipment_id"
        case lineNumber = "line_number"
        case sku
        case description
        case expectedQty = "expected_qty"
        case receivedQty = "received_qty"
        case uom
        case status
    }
}

struct ReceivingEventLineRequest: Codable, Equatable {
    var inboundLineId: String?
    var sku: String?
    var quantityExpected: Double?
    var quantityReceived: Double
    var conditionStatus: String?

    enum CodingKeys: String, CodingKey {
        case inboundLineId = "inbound_line_id"
        case sku
        case quantityExpected = "quantity_expected"
        case quantityReceived = "quantity_received"
        case conditionStatus = "condition_status"
    }
}

struct CreateReceivingEventRequest: Codable, Equatable {
    let orgId: String
    let facilityId: String
    var appointmentId: String?
    var inboundShipmentId: String?
    let eventType: String
    var status: String?
    var deviceId: String?
    let idempotencyKey: String
    var lines: [ReceivingEventLineRequest]

    enum CodingKeys: String, CodingKey {
        case orgId = "org_id"
        case facilityId = "facility_id"
        case appointmentId = "appointment_id"
        case inboundShipmentId = "inbound_shipment_id"
        case eventType = "event_type"
        case status
        case deviceId = "device_id"
        case idempotencyKey = "idempotency_key"
        case lines
    }

    static func makeIdempotencyKey() -> String {
        "ios-\(UUID().uuidString.lowercased())"
    }
}

struct ReceivingEventResponse: Decodable, Equatable {
    let mode: String
    let message: String?
    let duplicate: Bool?
}

enum ReceivingEventBuilder {
    static func buildRequest(
        environment: AppEnvironment,
        appointmentId: String?,
        shipmentId: String,
        lines: [InboundLineItem]
    ) -> CreateReceivingEventRequest {
        let eventLines = lines.compactMap { line -> ReceivingEventLineRequest? in
            guard line.receiveNow > 0 else { return nil }
            return ReceivingEventLineRequest(
                inboundLineId: line.id,
                sku: line.sku.isEmpty ? nil : line.sku,
                quantityExpected: line.expectedQty,
                quantityReceived: line.receiveNow,
                conditionStatus: "good"
            )
        }
        return CreateReceivingEventRequest(
            orgId: environment.orgId,
            facilityId: environment.facilityId,
            appointmentId: appointmentId,
            inboundShipmentId: shipmentId,
            eventType: "manual_receive",
            status: "committed",
            deviceId: ReceivingEventBuilder.deviceId,
            idempotencyKey: CreateReceivingEventRequest.makeIdempotencyKey(),
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
