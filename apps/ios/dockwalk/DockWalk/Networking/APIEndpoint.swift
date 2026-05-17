import Foundation

enum APIEndpoint {
    case health
    case appointments(orgId: String)
    case inboundShipments(orgId: String, appointmentId: String?)
    case inboundShipmentLines(shipmentId: String, orgId: String)
    case receivingEvents
    case auditEvents(orgId: String, limit: Int, offset: Int)
    case warehouseTasks(
        orgId: String,
        taskType: String?,
        status: String?,
        inboundShipmentId: String?,
        limit: Int,
        offset: Int
    )
    case warehouseTask(taskId: String, orgId: String)
    case syncEvents
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
        case .warehouseTasks: return "/api/tasks"
        case .warehouseTask(let taskId, _): return "/api/tasks/\(taskId)"
        case .syncEvents: return "/api/sync/events"
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
        case .warehouseTasks(let orgId, let taskType, let status, let inboundShipmentId, let limit, let offset):
            var items = [
                URLQueryItem(name: "org_id", value: orgId),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
            if let taskType {
                items.append(URLQueryItem(name: "task_type", value: taskType))
            }
            if let status {
                items.append(URLQueryItem(name: "status", value: status))
            }
            if let inboundShipmentId {
                items.append(URLQueryItem(name: "inbound_shipment_id", value: inboundShipmentId))
            }
            return items
        case .warehouseTask(_, let orgId):
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
