struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let v as String:
            try container.encode(v)
        case let v as Int:
            try container.encode(v)
        case let v as Bool:
            try container.encode(v)
        case let v as Double:
            try container.encode(v)
        case let v as [String: Any]:
            try container.encode(v.mapValues { AnyCodable($0) })
        case let v as [Any]:
            try container.encode(v.map { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // For simplicity, decode only as String — you can expand this
        if let str = try? container.decode(String.self) {
            value = str
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = ()
        }
    }
}

extension Dictionary where Key == String, Value == Any {
    func toAnyCodable() -> [String: AnyCodable] {
        mapValues { AnyCodable($0) }
    }
}
