import Foundation

enum APIEndpoint {
    case health
    case appointments(orgId: String)
    case inboundShipments(orgId: String, appointmentId: String?)
    case inboundShipmentLines(shipmentId: String, orgId: String)
    case receivingEvents
    case auditEvents(orgId: String, limit: Int, offset: Int)
    case inventoryItems
    case outboundOrders

    var path: String {
        switch self {
        case .health: return "/health"
        case .appointments: return "/api/appointments"
        case .inboundShipments: return "/api/inbound/shipments"
        case .inboundShipmentLines(let shipmentId, _):
            return "/api/inbound/shipments/\(shipmentId)/lines"
        case .receivingEvents: return "/api/inbound/receiving-events"
        case .auditEvents: return "/api/audit/events"
        case .inventoryItems: return "/api/inventory/items"
        case .outboundOrders: return "/api/outbound/orders"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .appointments(let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
        case .inboundShipments(let orgId, let appointmentId):
            var items = [URLQueryItem(name: "org_id", value: orgId)]
            if let appointmentId {
                items.append(URLQueryItem(name: "appointment_id", value: appointmentId))
            }
            return items
        case .inboundShipmentLines(_, let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
        case .auditEvents(let orgId, let limit, let offset):
            return [
                URLQueryItem(name: "org_id", value: orgId),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        default:
            return []
        }
    }

    func url(base: URL) -> URL? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var url = base.appending(path: trimmed)
        guard !queryItems.isEmpty else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? url
    }
}
