import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case httpStatus(Int, message: String?)
    case railwayHostUnavailable
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .transport(let error): return error.localizedDescription
        case .httpStatus(let code, let message):
            if let message, !message.isEmpty {
                return "HTTP \(code): \(message)"
            }
            return "HTTP \(code)"
        case .railwayHostUnavailable:
            return """
            DockWalk API host is not deployed on Railway (Application not found). \
            Redeploy dockwalk-api and confirm the base URL under More → API connection.
            """
        case .decoding(let error): return error.localizedDescription
        }
    }

    /// True when the API host is down or Railway has no app mapped to this domain.
    var isAPIHostUnreachable: Bool {
        switch self {
        case .railwayHostUnavailable, .transport, .invalidURL:
            return true
        case .httpStatus(let code, _):
            return code == 404 || code == 502 || code == 503
        case .decoding:
            return false
        }
    }
}

struct APIClient {
    let baseURL: URL
    let session: URLSession
    let decoder: JSONDecoder

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    func get<T: Decodable>(_ endpoint: APIEndpoint, as type: T.Type = T.self) async throws -> T {
        try await request(endpoint, method: "GET", body: Optional<Data>.none, as: type)
    }

    func post<T: Decodable, Body: Encodable>(
        _ endpoint: APIEndpoint,
        body: Body,
        as type: T.Type = T.self
    ) async throws -> T {
        let encoded = try JSONEncoder().encode(body)
        return try await request(endpoint, method: "POST", body: encoded, as: type)
    }

    func patch<T: Decodable, Body: Encodable>(
        _ endpoint: APIEndpoint,
        body: Body,
        as type: T.Type = T.self
    ) async throws -> T {
        let encoded = try JSONEncoder().encode(body)
        return try await request(endpoint, method: "PATCH", body: encoded, as: type)
    }

    func fetchHealth() async throws -> HealthResponse {
        try await get(.health)
    }

    func healthCheck() async -> Bool {
        do {
            _ = try await fetchHealth()
            return true
        } catch {
            return false
        }
    }

    func fetchAuditEvents(
        orgId: String,
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> AuditEventsListResponse {
        try await get(.auditEvents(orgId: orgId, limit: limit, offset: offset))
    }

    func fetchTasks(
        orgId: String,
        taskType: String? = "putaway",
        status: String? = nil,
        inboundShipmentId: String? = nil,
        limit: Int = 25,
        offset: Int = 0
    ) async throws -> WarehouseTasksListResponse {
        try await get(
            .warehouseTasks(
                orgId: orgId,
                taskType: taskType,
                status: status,
                inboundShipmentId: inboundShipmentId,
                limit: limit,
                offset: offset
            )
        )
    }

    func fetchTask(id: String, orgId: String) async throws -> WarehouseTaskDetailResponse {
        try await get(.warehouseTask(taskId: id, orgId: orgId))
    }

    func assignTask(taskId: String, body: TaskAssignRequest) async throws -> WarehouseTaskWriteResponse {
        try await post(.warehouseTaskAssign(taskId: taskId), body: body)
    }

    func startTask(taskId: String, body: TaskStartRequest) async throws -> WarehouseTaskWriteResponse {
        try await post(.warehouseTaskStart(taskId: taskId), body: body)
    }

    func blockTask(taskId: String, body: TaskBlockRequest) async throws -> WarehouseTaskWriteResponse {
        try await post(.warehouseTaskBlock(taskId: taskId), body: body)
    }

    func completeTask(taskId: String, body: TaskCompleteRequest) async throws -> WarehouseTaskWriteResponse {
        try await post(.warehouseTaskComplete(taskId: taskId), body: body)
    }

    func postSyncEvents(_ envelope: SyncBatchEnvelope) async throws -> SyncBatchResponse {
        try await post(.syncEvents, body: envelope)
    }

    func fetchFacilityConfig(facilityId: String) async throws -> FacilityConfigResponse {
        try await get(.facilityConfig(facilityId: facilityId))
    }

    func fetchFacilityLocations(facilityId: String, limit: Int, offset: Int) async throws -> FacilityLocationsResponse {
        try await get(.facilityLocations(facilityId: facilityId, limit: limit, offset: offset))
    }

    func fetchFacilityLocation(facilityId: String, code: String) async throws -> FacilityLocationLookupResponse {
        try await get(.facilityLocationLookup(facilityId: facilityId, code: code))
    }

    func searchCatalog(facilityId: String, query: String, limit: Int = 25) async throws -> CatalogSearchResponse {
        try await get(.catalogSearch(facilityId: facilityId, query: query, limit: limit))
    }

    func lookupCatalog(facilityId: String, upc: String) async throws -> CatalogLookupResponse {
        try await get(.catalogLookup(facilityId: facilityId, upc: upc))
    }

    func finalizeInboundLoad(loadId: String, body: InboundFinalizeRequest) async throws {
        let _: EmptyAPIResponse = try await post(.inboundFinalize(loadId: loadId), body: body)
    }

    func postInventoryMovement(_ body: InventoryMovementRequest) async throws {
        let _: EmptyAPIResponse = try await post(.inventoryMovement, body: body)
    }

    func updateAppointment(id: String, orgId: String, body: AppointmentUpdateRequest) async throws -> AppointmentItemResponse {
        try await patch(.appointment(id: id, orgId: orgId), body: body)
    }

    func transitionOutboundOrder(orderId: String, body: OutboundOrderTransitionRequest) async throws -> OutboundOrderTransitionResponse {
        try await post(.outboundOrderTransition(id: orderId), body: body)
    }

    func fetchOutboundOrders(orgId: String) async throws -> OutboundOrdersResponse {
        try await get(.outboundOrders(orgId: orgId))
    }

    func fetchOutboundOrder(orderId: String, orgId: String) async throws -> OutboundOrderDetailResponse {
        try await get(.outboundOrder(id: orderId, orgId: orgId))
    }

    func fetchOutboundOrderLines(orderId: String, orgId: String) async throws -> OutboundOrderLinesResponse {
        try await get(.outboundOrderLines(id: orderId, orgId: orgId))
    }

    private func request<T: Decodable, Body>(
        _ endpoint: APIEndpoint,
        method: String,
        body: Body?,
        as type: T.Type
    ) async throws -> T {
        guard let url = endpoint.url(base: baseURL) else {
            throw APIClientError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body = body as? Data {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIClientError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIClientError.transport(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 404, Self.isRailwayApplicationNotFound(data) {
                throw APIClientError.railwayHostUnavailable
            }
            let message = Self.parseAPIErrorMessage(from: data)
            throw APIClientError.httpStatus(http.statusCode, message: message)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error)
        }
    }

    private static func parseAPIErrorMessage(from data: Data) -> String? {
        guard let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data) else {
            return nil
        }
        return decoded.error.message
    }

    private struct RailwayPlatformError: Decodable {
        let status: String?
        let message: String?
    }

    static func isRailwayApplicationNotFound(_ data: Data) -> Bool {
        guard let decoded = try? JSONDecoder().decode(RailwayPlatformError.self, from: data) else {
            return false
        }
        return decoded.status == "error"
            && decoded.message?.localizedCaseInsensitiveContains("application not found") == true
    }
}

extension Error {
    var isDockWalkAPIHostUnreachable: Bool {
        if let apiError = self as? APIClientError {
            return apiError.isAPIHostUnreachable
        }
        return false
    }
}

struct HealthResponse: Decodable, Equatable {
    let status: String?
    let service: String?
    let environment: String?
    let supabase: String?
}
