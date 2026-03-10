import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE, PATCH
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL"
        case .invalidResponse: return "Geçersiz sunucu yanıtı"
        case .httpError(let code, let msg): return "HTTP Hatası \(code): \(msg ?? "")"
        case .decodingError(let err): return "Veri işleme hatası: \(err.localizedDescription)"
        case .networkError(let err): return "Ağ hatası: \(err.localizedDescription)"
        case .unauthorized: return "Oturum süresi doldu"
        case .serverError(let msg): return "Sunucu hatası: \(msg)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.baseURL = AppConfig.apiBaseURL

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let url = try buildURL(endpoint: endpoint, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth {
            guard let token = UserDefaultsManager.shared.authToken else {
                throw APIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        case 401:
            // Try refresh token
            if let newToken = try? await refreshToken() {
                UserDefaultsManager.shared.authToken = newToken
                request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await session.data(for: request)
                guard let retryHTTP = retryResponse as? HTTPURLResponse, (200...299).contains(retryHTTP.statusCode) else {
                    throw APIError.unauthorized
                }
                return try decoder.decode(T.self, from: retryData)
            }
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    func upload<T: Decodable>(
        endpoint: String,
        imageData: Data,
        additionalFields: [String: String]? = nil
    ) async throws -> T {
        let url = try buildURL(endpoint: endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if let token = UserDefaultsManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Image field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Additional fields
        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }

    private func buildURL(endpoint: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        return url
    }

    private func refreshToken() async throws -> String {
        guard let refreshToken = UserDefaultsManager.shared.refreshToken else {
            throw APIError.unauthorized
        }

        struct RefreshRequest: Encodable { let refreshToken: String }
        struct RefreshResponse: Decodable { let accessToken: String; let refreshToken: String }

        let response: RefreshResponse = try await request(
            endpoint: "/auth/refresh",
            method: .POST,
            body: RefreshRequest(refreshToken: refreshToken),
            requiresAuth: false
        )

        UserDefaultsManager.shared.refreshToken = response.refreshToken
        return response.accessToken
    }
}

// Helper for encoding any Encodable
struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        self.encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
