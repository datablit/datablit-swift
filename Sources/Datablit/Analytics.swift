import Foundation

enum EventType: String, Codable {
    case invalid, identify, track
}

struct Event: Codable {
    let anonymousId: String
    let userId: String?
    let messageId: String
    var type: EventType
    var context: [String: AnyCodable]?
    let originalTimestamp: String
    var event: String?
    var properties: [String: AnyCodable]?
    var traits: [String: AnyCodable]?
    let writeKey: String
}

public class Analytics {
    //private var shared: Analytics

    private var config : Configuration
    private var queue: [Event] = []
    private var userId: String?
    private var anonymousId: String
    private var timer: Timer?
    private var context: [String: Any] = [:]

    public init(config: Configuration) {
        self.config = config
        self.anonymousId = Self.getAnonymousId()
        self.context = [
            "library": [
                "name": "@d1414k/analytics-swift",
                "version": "1.0.0"
            ]
        ]
        //restoreQueue()
//        startFlushTimer()
    }

    public func identify(userId: String, traits: [String: Any] = [:]) {
        self.userId = userId
        UserDefaults.standard.set(userId, forKey: "analytics_user_id")
        var event = defaultEvent()
        event.type = .identify
        event.traits = traits.mapValues { AnyCodable($0) }
        event.context = nil
        addToQueue(event)
    }

    public func track(eventName: String, properties: [String: Any] = [:]) {
        var event = defaultEvent()
        event.type = .track
        event.event = eventName
        event.properties = properties.mapValues { AnyCodable($0) }
        addToQueue(event)
    }

    private func defaultEvent() -> Event {
        return Event(
            anonymousId: self.anonymousId,
            userId: self.userId ?? UserDefaults.standard.string(forKey: "analytics_user_id"),
            messageId: UUID().uuidString,
            type: .invalid,
            context: context.mapValues { AnyCodable($0) },
            originalTimestamp: ISO8601DateFormatter().string(from: Date()),
            event: nil,
            properties: nil,
            traits: nil,
            writeKey: config.writeKey
        )
    }

    private func addToQueue(_ event: Event) {
        queue.append(event)
        saveQueue()
        if queue.count >= config.flushAt {
            flush()
        }
    }

    private func flush() {
        guard !queue.isEmpty else { return }
 
        let batch = queue
        let payload : [String: AnyCodable] = [
            "batch": AnyCodable(batch),
            "sentAt": AnyCodable(ISO8601DateFormatter().string(from: Date()))
        ]

        guard let jsonData = try? JSONEncoder().encode(payload) else { return }

        var request = URLRequest(url: URL(string: config.endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        queue = []
        saveQueue()

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("[Analytics]: Retry on failure", error)
//                self.queue.append(contentsOf: batch)
//                self.saveQueue()
            } else if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                print("[Analytics]: Skipping event due to client error", response.statusCode)
            }
        }.resume()
    }

//    private func startFlushTimer() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.flushInterval), repeats: true) { _ in
//           self.flush()
//        }
//    }

    private func saveQueue() {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: "analytics_event_queue")
    }

//    private func restoreQueue() {
//        guard let data = UserDefaults.standard.data(forKey: "analytics_event_queue"),
//              let restored = try? JSONDecoder().decode([Event].self, from: data) else { return }
//        self.queue = restored
//    }

    private static func getAnonymousId() -> String {
        if let id = UserDefaults.standard.string(forKey: "analytics_anonymous_id") {
            return id
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "analytics_anonymous_id")
        return newId
    }
}

