import Foundation

// MARK: - Event Types

/// Represents the type of analytics event
public enum EventType: String, Codable, Sendable {
    case invalid, identify, track
}

// MARK: - Event Model

/// Represents an analytics event with all necessary metadata
public struct Event: Codable, Sendable {
    /// Anonymous identifier for the user
    public var anonymousId: String
    
    /// User identifier (optional)
    public var userId: String?
    
    /// Unique message identifier
    public var messageId: String
    
    /// Type of the event
    public var type: EventType
    
    /// Context information about the event
    public var context: [String: AnyCodable]?
    
    /// Original timestamp when the event occurred
    public var originalTimestamp: String
    
    /// Event name (for track events)
    public var event: String?
    
    /// Event properties (for track events)
    public var properties: [String: AnyCodable]?
    
    /// User traits (for identify events)
    public var traits: [String: AnyCodable]?
    
    /// Initializes a new Event
    /// - Parameters:
    ///   - anonymousId: Anonymous identifier for the user
    ///   - userId: User identifier (optional)
    ///   - messageId: Unique message identifier
    ///   - type: Type of the event
    ///   - context: Context information about the event
    ///   - originalTimestamp: Original timestamp when the event occurred
    ///   - event: Event name (for track events)
    ///   - properties: Event properties (for track events)
    ///   - traits: User traits (for identify events)
    public init(
        anonymousId: String,
        userId: String?,
        messageId: String,
        type: EventType,
        context: [String: AnyCodable]?,
        originalTimestamp: String,
        event: String?,
        properties: [String: AnyCodable]?,
        traits: [String: AnyCodable]?
    ) {
        self.anonymousId = anonymousId
        self.userId = userId
        self.messageId = messageId
        self.type = type
        self.context = context
        self.originalTimestamp = originalTimestamp
        self.event = event
        self.properties = properties
        self.traits = traits
    }
}

// MARK: - Event Extensions

extension Event {
    /// Converts the event to a dictionary representation
    /// - Returns: Dictionary representation of the event
    func toDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}
