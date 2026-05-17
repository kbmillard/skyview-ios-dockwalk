import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case transport(Error)
    case httpStatus(Int)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .transport(let error): return error.localizedDescription
        case .httpStatus(let code): return "HTTP \(code)"
        case .decoding(let error): return error.localizedDescription
        }
    }
}

struct APIClient {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
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

    func healthCheck() async -> Bool {
        do {
            let _: HealthResponse = try await get(.health)
            return true
        } catch {
            return false
        }
    }

    private func request<T: Decodable, Body>(
        _ endpoint: APIEndpoint,
        method: String,
        body: Body?,
        as type: T.Type
    ) async throws -> T {
        let url = endpoint.url(base: baseURL)
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
            throw APIClientError.httpStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error)
        }
    }
}

struct HealthResponse: Decodable {
    let ok: Bool?
    let status: String?
}
