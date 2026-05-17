import Foundation

enum APIEndpoint {
    case health
    case appointments(orgId: String)
    case inboundShipments
    case inventoryItems
    case outboundOrders

    var path: String {
        switch self {
        case .health: return "/health"
        case .appointments: return "/api/appointments"
        case .inboundShipments: return "/api/inbound/shipments"
        case .inventoryItems: return "/api/inventory/items"
        case .outboundOrders: return "/api/outbound/orders"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .appointments(let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
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
