import Foundation

// MARK: - Experiment Models

/// Request model for getting experiment variant
public struct GetVariantRequest: Codable, Sendable {
    /// The experiment ID
    public let expId: String
    
    /// The entity ID (user ID)
    public let entityId: String
    
    /// Initializes a new GetVariantRequest
    /// - Parameters:
    ///   - expId: The experiment ID
    ///   - entityId: The entity ID (user ID)
    public init(expId: String, entityId: String) {
        self.expId = expId
        self.entityId = entityId
    }
}

/// Response model for getting experiment variant
public struct GetVariantResponse: Codable, Sendable {
    /// The experiment ID
    public let expId: String
    
    /// The entity ID (user ID)
    public let entityId: String
    
    /// The variant assigned to the user
    public let variant: String
    
    /// Initializes a new GetVariantResponse
    /// - Parameters:
    ///   - expId: The experiment ID
    ///   - entityId: The entity ID (user ID)
    ///   - variant: The variant assigned to the user
    public init(expId: String, entityId: String, variant: String) {
        self.expId = expId
        self.entityId = entityId
        self.variant = variant
    }
}

// MARK: - Experiment Class

/// A class for managing experiments with Datablit
@available(macOS 10.15, iOS 13.0, *)
public final class Experiment: @unchecked Sendable {
    private let networkClient: NetworkClient
    
    /// Initializes a new Experiment instance
    /// - Parameters:
    ///   - apiKey: The Datablit API key
    ///   - apiBaseURL: The base URL for the Datablit console
    public init(apiKey: String, apiBaseURL: String = "https://console.datablit.com") {
        self.networkClient = NetworkClient(apiKey: apiKey, apiBaseURL: apiBaseURL)
    }
    
    /// Get experiment variant for a user
    /// - Parameters:
    ///   - expId: The experiment ID
    ///   - entityId: The entity ID (user ID)
    /// - Returns: The experiment variant response with expId, entityId, and variant
    public func getVariant(expId: String, entityId: String) async throws -> GetVariantResponse {
        let queryItems = [
            URLQueryItem(name: "expId", value: expId),
            URLQueryItem(name: "entityId", value: entityId)
        ]
        
        return try await networkClient.makeRequest(
            endpoint: "/api/1.0/experiment/variant",
            method: "GET",
            queryItems: queryItems
        )
    }
}
