import Foundation

enum APIEndpoint {
    case health
    case appointments
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

    func url(base: URL) -> URL {
        base.appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
