import Foundation

// MARK: - Rule Evaluation Models

/// Request model for rule evaluation
public struct EvalRuleRequest: Codable, Sendable {
    /// The rule key to evaluate
    public let key: String
    
    /// The user ID for the evaluation
    public let userId: String
    
    /// Optional parameters for the rule evaluation
    public let params: [String: AnyCodable]?
    
    /// Initializes a new EvalRuleRequest
    /// - Parameters:
    ///   - key: The rule key to evaluate
    ///   - userId: The user ID for the evaluation
    ///   - params: Optional parameters for the rule evaluation
    public init(key: String, userId: String, params: [String: AnyCodable]? = nil) {
        self.key = key
        self.userId = userId
        self.params = params
    }
}

/// Response model for rule evaluation
public struct EvalRuleResponse: Codable, Sendable {
    /// The rule key that was evaluated
    public let key: String
    
    /// The user ID that was evaluated
    public let userId: String
    
    /// The evaluation result (true/false)
    public let result: Bool
    
    /// Initializes a new EvalRuleResponse
    /// - Parameters:
    ///   - key: The rule key that was evaluated
    ///   - userId: The user ID that was evaluated
    ///   - result: The evaluation result
    public init(key: String, userId: String, result: Bool) {
        self.key = key
        self.userId = userId
        self.result = result
    }
}

// MARK: - Rule Class

/// A class for evaluating rules with Datablit
@available(macOS 10.15, iOS 13.0, *)
public final class Rule: @unchecked Sendable {
    private let networkClient: NetworkClient
    
    /// Initializes a new Rule instance
    /// - Parameters:
    ///   - apiKey: The Datablit API key
    ///   - apiBaseURL: The base URL for the Datablit console
    public init(apiKey: String, apiBaseURL: String = "https://console.datablit.com") {
        self.networkClient = NetworkClient(apiKey: apiKey, apiBaseURL: apiBaseURL)
    }
    
    /// Evaluate a rule for a given user and context
    /// - Parameters:
    ///   - key: The rule key to evaluate
    ///   - userId: The user ID for the evaluation
    ///   - params: Optional parameters for the rule evaluation
    /// - Returns: The evaluation result with key, userId, and result
    public func evalRule(key: String, userId: String, params: [String: Any]? = nil) async throws -> EvalRuleResponse {
        let request = EvalRuleRequest(
            key: key,
            userId: userId,
            params: params?.mapValues { AnyCodable($0) }
        )
        
        let encoder = JSONEncoder()
        let body = try encoder.encode(request)
        
        return try await networkClient.makeRequest(
            endpoint: "/api/1.0/rule/eval",
            method: "POST",
            body: body
        )
    }
}
