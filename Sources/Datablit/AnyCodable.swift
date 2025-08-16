import Foundation

/// A type that can encode and decode any value that can be represented as JSON
public struct AnyCodable: Codable, @unchecked Sendable {
    /// The underlying value
    public var value: Any

    /// Initializes with any value
    /// - Parameter value: The value to wrap
    public init(_ value: Any) {
        self.value = value
    }

    /// Encodes the value to the given encoder
    /// - Parameter encoder: The encoder to encode to
    /// - Throws: Encoding errors
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is String: try container.encode(value as! String)
        case is Int: try container.encode(value as! Int)
        case is Double: try container.encode(value as! Double)
        case is Bool: try container.encode(value as! Bool)
        case is [Any]: try container.encode((value as! [Any]).map { AnyCodable($0) })
        case is [String: Any]: try container.encode((value as! [String: Any]).mapValues { AnyCodable($0) })
        default: try container.encodeNil()
        }
    }

    /// Decodes a value from the given decoder
    /// - Parameter decoder: The decoder to decode from
    /// - Throws: Decoding errors
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self.value = str
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let dbl = try? container.decode(Double.self) {
            self.value = dbl
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let arr = try? container.decode([AnyCodable].self) {
            self.value = arr.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues { $0.value }
        } else {
            self.value = ()
        }
    }
}
