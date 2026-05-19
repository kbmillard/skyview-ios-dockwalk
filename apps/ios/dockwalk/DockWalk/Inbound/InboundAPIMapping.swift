import Foundation

enum InboundAPIMapping {
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

    static func parseDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        return isoFormatter.date(from: raw) ?? isoFormatterNoFraction.date(from: raw)
    }

    static func mapAppointment(_ dto: AppointmentDTO) -> ReceivingAppointment {
        let metadata = dto.metadata ?? [:]
        let carrier = metadata["carrier_name"]?.stringValue
            ?? metadata["carrier"]?.stringValue
            ?? shortLabel(prefix: "Carrier", id: dto.carrierId)
        let dock = metadata["dock_name"]?.stringValue
            ?? metadata["dock"]?.stringValue
            ?? shortLabel(prefix: "Dock", id: dto.dockId)
        let pallets = metadata["pallet_count"]?.intValue
            ?? metadata["pallets"]?.intValue
            ?? 0

        return ReceivingAppointment(
            id: dto.id,
            carrier: carrier,
            dock: dock,
            scheduledAt: parseDate(dto.scheduledAt) ?? .now,
            status: mapInboundLoadStatus(dto.status),
            poNumber: dto.referenceNumber ?? "—",
            palletCount: pallets
        )
    }

    static func mapInboundShipment(_ dto: InboundShipmentDTO) -> InboundShipmentItem {
        InboundShipmentItem(
            id: dto.id,
            appointmentId: dto.appointmentId,
            referenceNumber: dto.referenceNumber ?? "—",
            status: mapInboundLoadStatus(dto.status),
            expectedAt: parseDate(dto.expectedAt),
            receivedAt: parseDate(dto.receivedAt)
        )
    }

    static func mapInboundLine(_ dto: InboundLineDTO) -> InboundLineItem {
        let expected = dto.expectedQty ?? 0
        let received = dto.receivedQty ?? 0
        return InboundLineItem(
            id: dto.id,
            sku: dto.sku ?? "—",
            description: dto.description ?? "Inbound line",
            expectedQty: expected,
            receivedQty: received,
            quantityDamaged: dto.quantityDamaged ?? 0,
            receiveNow: max(0, expected - received),
            uom: dto.uom ?? "ea",
            status: dto.status ?? "expected"
        )
    }

    static func mapShipmentToReceivedLine(_ shipment: InboundShipmentItem) -> ReceivedLine {
        ReceivedLine(
            id: shipment.id,
            sku: shipment.referenceNumber,
            description: "Inbound shipment · \(shipment.status.displayName)",
            quantity: 1
        )
    }

    /// Map API status string to unified inbound load status
    static func mapInboundLoadStatus(_ raw: String?) -> InboundLoadStatus {
        guard let raw = raw?.lowercased() else { return .scheduled }
        
        switch raw {
        case "scheduled": return .scheduled
        case "arrived", "checked_in": return .checkedIn
        case "staged": return .staged
        case "receiving": return .receiving
        case "completed", "complete": return .complete
        case "cancelled", "missed", "refused": return .cancelled
        default: return .scheduled
        }
    }

    private static func shortLabel(prefix: String, id: String?) -> String {
        guard let id, !id.isEmpty else { return "\(prefix) —" }
        return "\(prefix) \(id.prefix(8))"
    }
}
