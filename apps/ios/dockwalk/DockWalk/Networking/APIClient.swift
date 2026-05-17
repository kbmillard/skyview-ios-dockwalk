import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case httpStatus(Int, message: String?)
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
        case .decoding(let error): return error.localizedDescription
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

    func postSyncEvents(_ envelope: SyncBatchEnvelope) async throws -> SyncBatchResponse {
        try await post(.syncEvents, body: envelope)
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
}

struct HealthResponse: Decodable, Equatable {
    let status: String?
    let service: String?
    let environment: String?
    let supabase: String?
}
