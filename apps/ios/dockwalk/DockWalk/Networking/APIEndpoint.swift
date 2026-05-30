import Foundation

enum APIEndpoint {
    case health
    case appointments(orgId: String)
    case appointment(id: String, orgId: String)
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
    case warehouseTaskAssign(taskId: String)
    case warehouseTaskStart(taskId: String)
    case warehouseTaskBlock(taskId: String)
    case warehouseTaskComplete(taskId: String)
    case syncEvents
    case inventoryItems
    case outboundOrders(orgId: String)
    case outboundOrder(id: String, orgId: String)
    case outboundOrderLines(id: String, orgId: String)
    case outboundOrderTransition(id: String)
    case facilityConfig(facilityId: String)
    case facilityLocations(facilityId: String, limit: Int, offset: Int)
    case facilityLocationLookup(facilityId: String, code: String)
    case catalogSearch(facilityId: String, query: String, limit: Int)
    case catalogLookup(facilityId: String, upc: String)
    case inboundFinalize(loadId: String)
    case inventoryMovement

    var path: String {
        switch self {
        case .health: return "/health"
        case .appointments: return "/api/appointments"
        case .appointment(let id, _): return "/api/appointments/\(id)"
        case .inboundShipments: return "/api/inbound/shipments"
        case .inboundShipmentLines(let shipmentId, _):
            return "/api/inbound/shipments/\(shipmentId)/lines"
        case .receivingEvents: return "/api/inbound/receiving-events"
        case .auditEvents: return "/api/audit/events"
        case .warehouseTasks: return "/api/tasks"
        case .warehouseTask(let taskId, _): return "/api/tasks/\(taskId)"
        case .warehouseTaskAssign(let taskId): return "/api/tasks/\(taskId)/assign"
        case .warehouseTaskStart(let taskId): return "/api/tasks/\(taskId)/start"
        case .warehouseTaskBlock(let taskId): return "/api/tasks/\(taskId)/block"
        case .warehouseTaskComplete(let taskId): return "/api/tasks/\(taskId)/complete"
        case .syncEvents: return "/api/sync/events"
        case .inventoryItems: return "/api/inventory/items"
        case .outboundOrders: return "/api/outbound/orders"
        case .outboundOrder(let id, _): return "/api/outbound/orders/\(id)"
        case .outboundOrderLines(let id, _): return "/api/outbound/orders/\(id)/lines"
        case .outboundOrderTransition(let id): return "/api/outbound/orders/\(id)/transition"
        case .facilityConfig(let facilityId):
            return "/api/facilities/\(facilityId)/config"
        case .facilityLocations(let facilityId, _, _):
            return "/api/facilities/\(facilityId)/locations"
        case .facilityLocationLookup(let facilityId, let code):
            return "/api/facilities/\(facilityId)/locations/\(code.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? code)"
        case .catalogSearch(let facilityId, _, _):
            return "/api/facilities/\(facilityId)/catalog/search"
        case .catalogLookup(let facilityId, _):
            return "/api/facilities/\(facilityId)/catalog/lookup"
        case .inboundFinalize(let loadId):
            return "/api/inbound/loads/\(loadId)/finalize"
        case .inventoryMovement:
            return "/api/inventory/movements"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .appointments(let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
        case .appointment(_, let orgId):
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
        case .facilityLocations(_, let limit, let offset):
            return [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
            ]
        case .catalogSearch(_, let query, let limit):
            return [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        case .catalogLookup(_, let upc):
            return [URLQueryItem(name: "upc", value: upc)]
        case .outboundOrders(let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
        case .outboundOrder(_, let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
        case .outboundOrderLines(_, let orgId):
            return [URLQueryItem(name: "org_id", value: orgId)]
        default:
            return []
        }
    }

    func url(base: URL) -> URL? {
        let trimmed = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = base.appending(path: trimmed)
        guard !queryItems.isEmpty else { return url }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        return components?.url ?? url
    }
}
