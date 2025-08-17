import Foundation

// MARK: - Network Client

/// A shared network client for making HTTP requests
@available(macOS 10.15, iOS 13.0, *)
internal final class NetworkClient: @unchecked Sendable {
    private let apiKey: String
    private let apiBaseURL: String
    
    /// Initializes a new NetworkClient instance
    /// - Parameters:
    ///   - apiKey: The Datablit API key
    ///   - apiBaseURL: The base URL for the Datablit console
    init(apiKey: String, apiBaseURL: String) {
        self.apiKey = apiKey
        self.apiBaseURL = apiBaseURL
    }
    
    /// Makes a generic HTTP request
    /// - Parameters:
    ///   - endpoint: The API endpoint path (e.g., "/api/1.0/rule/eval")
    ///   - method: The HTTP method
    ///   - body: Optional request body data
    ///   - queryItems: Optional query parameters
    /// - Returns: The response data
    func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        var urlComponents = URLComponents(string: "\(apiBaseURL)\(endpoint)")
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw DatablitError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue(apiKey, forHTTPHeaderField: "apiKey")
        
        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = body
        }
        
        let (data, response): (Data, URLResponse)
        
        if #available(macOS 12.0, iOS 15.0, *) {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } else {
            // Fallback for older versions
            (data, response) = try await withCheckedThrowingContinuation { continuation in
                URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else {
                        continuation.resume(throwing: DatablitError.invalidResponse)
                    }
                }.resume()
            }
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DatablitError.invalidResponse
        }
        
        if !httpResponse.statusCode.isSuccess {
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["message"] as? String ?? "Unknown error"
            throw DatablitError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - HTTP Status Code Extension

private extension Int {
    var isSuccess: Bool {
        return self == 200
    }
}
