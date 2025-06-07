import SwiftUI
import Foundation
import SystemConfiguration
import Network
#if canImport(UIKit)
import UIKit
#endif


enum EventType: String, Codable {
    case invalid, identify, track
}

struct Event: Codable {
    var anonymousId: String
    var userId: String?
    var messageId: String
    var type: EventType
    var context: [String: AnyCodable]?
    var originalTimestamp: String
    var event: String?
    var properties: [String: AnyCodable]?
    var traits: [String: AnyCodable]?
}

public final class Analytics : @unchecked Sendable{
    public static let shared = Analytics()

    private var apiURL: String = ""
    private var writeKey: String = ""
    private var anonymousId: String = UUID().uuidString
    private var userId: String?
    private var context: [String: AnyCodable] = [:]

    private var queue: [Event] = []
    private var flushAt = 20
    private var flushInterval: TimeInterval = 30
    private var timer: Timer?

    private let queueDispatch = DispatchQueue(label: "com.sdk.message.queue")

    private init() {}

    @MainActor
    public func initialize(
        writeKey: String,
        apiURL: String = "http://api.datablit.com:30081/v1/batch",
        flushAt: Int = 20,
        flushInterval: TimeInterval = 30.0,
        trackApplicationLifecycleEvents: Bool = false
    ) {
        self.writeKey = writeKey
        self.apiURL = apiURL
        self.flushAt = flushAt
        self.flushInterval = flushInterval

        self.anonymousId = loadOrGenerateAnonymousId()
        self.userId = UserDefaults.standard.string(forKey: "sdk_user_id")
        setupContext()

        if trackApplicationLifecycleEvents {
            setupLifecycleTracking()
        }

        startFlushTimer()
    }

    public func identify(userId: String, traits: [String: Any] = [:]) {
        self.userId = userId
        UserDefaults.standard.set(userId, forKey: "sdk_user_id")

        var event = getDefaultEvent()
        event.type = .identify
        event.traits = traits.mapValues { AnyCodable($0) }
        event.context = context

        addToQueue(event)
    }
    
    public func identify<T: Encodable>(userId: String, traits: T) {
        guard let encoded = try? JSONEncoder().encode(traits),
              let json = try? JSONSerialization.jsonObject(with: encoded),
              let dict = json as? [String: Any] else {
            print("❌ Failed to encode encodable traits")
            return
        }
        identify(userId: userId, traits: dict)
    }

    public func track(eventName: String, properties: [String: Any] = [:]) {
        var event = getDefaultEvent()
        event.type = .track
        event.event = eventName
        event.context = context
        event.properties = properties.mapValues { AnyCodable($0) }

        addToQueue(event)
    }
    
    public func track<T: Encodable>(eventName: String, properties: T) {
        guard let encoded = try? JSONEncoder().encode(properties),
              let json = try? JSONSerialization.jsonObject(with: encoded),
              let dict = json as? [String: Any] else {
            print("❌ Failed to encode encodable properties")
            return
        }
        track(eventName: eventName, properties: dict)
    }

    private func getDefaultEvent() -> Event {
        return Event(
            anonymousId: self.anonymousId,
            userId: self.userId,
            messageId: UUID().uuidString,
            type: .invalid,
            context: context,
            originalTimestamp: ISO8601DateFormatter().string(from: Date()),
            event: nil,
            properties: nil,
            traits: nil
        )
    }

    private func addToQueue(_ event: Event) {
        queueDispatch.async {
            if self.queue.count > 100 { // If payload size will be huge, it will start failing while traying to upload. so better drop it, it will be used in case of backend is down
                self.queue.removeAll()
            }
            self.queue.append(event)
            if self.queue.count >= self.flushAt {
                self.flush()
            }
        }
    }

    public func flush() {
        queueDispatch.async {
            guard !self.queue.isEmpty else { return }

            let batch = self.queue
            self.queue.removeAll()

            let payload: [String: Any] = [
                "sentAt": ISO8601DateFormatter().string(from: Date()),
                "batch": batch.map { $0.toDictionary() }
            ]

            guard let url = URL(string: self.apiURL),
                  let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                print("❌ Invalid URL or payload")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(self.writeKey, forHTTPHeaderField: "write_key")
            request.httpBody = data

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Flush failed:", error.localizedDescription)
                    self.queueDispatch.async {
                        self.queue = batch + self.queue
                    }
                    return
                }

                if let response = response as? HTTPURLResponse {
                    print("✅ Status:", response.statusCode)
                }
            }.resume()
        }
    }

    private func startFlushTimer() {
        DispatchQueue.main.async {
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: self.flushInterval, repeats: true) { [weak self] _ in
                self?.flush()
            }
        }
    }

    private func loadOrGenerateAnonymousId() -> String {
        if let id = UserDefaults.standard.string(forKey: "sdk_anonymous_id") {
            return id
        }
        let id = UUID().uuidString
        UserDefaults.standard.set(id, forKey: "sdk_anonymous_id")
        return id
    }

    @MainActor
    private func setupContext() {
        #if canImport(UIKit)
        let device = UIDevice.current
        let screen = UIScreen.main.bounds
        let bundle = Bundle.main

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        // App Info
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let appName = bundle.infoDictionary?["CFBundleName"] as? String ?? "unknown"
        let appBuild = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        let appNamespace = bundle.bundleIdentifier ?? "unknown"

        // OS Version
        let osName = "iOS"
        let osVersion = device.systemVersion

        let network = [
            "wifi": NetworkStatus.shared.isWiFi,
            "bluetooth": false,
            "cellular": NetworkStatus.shared.isCellular
        ]

        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS \(osVersion.replacingOccurrences(of: ".", with: "_")) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile"

        self.context = [
            "device": AnyCodable([
                "name": "iPhone",
                "manufacturer": "Apple",
                "model": "arm64",
                "id": deviceId,
                "type": "ios"
            ]),
            "screen": AnyCodable([
                "height": Int(screen.height),
                "width": Int(screen.width)
            ]),
            "userAgent": AnyCodable(userAgent),
            "library": AnyCodable([
                "name": "analytics-swift",
                "version": "1.7.3"
            ]),
            "app": AnyCodable([
                "version": appVersion,
                "name": appName,
                "build": appBuild,
                "namespace": appNamespace
            ]),
            "locale": AnyCodable(Locale.current.identifier),
            "network": AnyCodable(network),
            "os": AnyCodable([
                "name": osName,
                "version": osVersion
            ]),
            "timezone": AnyCodable(TimeZone.current.identifier),
        ]
        #else
        print("❌ setupContext(): UIKit not available. Skipping context population.")
        #endif
    }
    
    @MainActor
    private func setupLifecycleTracking() {
        #if canImport(UIKit)
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(self, selector: #selector(appDidFinishLaunching), name: UIApplication.didFinishLaunchingNotification, object: nil)
        #endif
    }

    @objc private func appDidBecomeActive() {
        track(eventName: "Application Active")
    }

    @objc private func appDidEnterBackground() {
        track(eventName: "Application Backgrounded")
    }

    @objc private func appWillEnterForeground() {
        track(eventName: "Application Foreground")
    }

    @objc private func appDidFinishLaunching() {
        track(eventName: "Application Launched")
    }

}


struct AnyCodable: Codable, @unchecked Sendable {
    var value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
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

    init(from decoder: Decoder) throws {
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

extension Event {
    func toDictionary() -> [String: Any] {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

final class NetworkStatus: @unchecked Sendable {
    static let shared = NetworkStatus()
    private let queue = DispatchQueue(label: "com.sdk.network.monitor")

    private(set) var isWiFi: Bool = false
    private(set) var isCellular: Bool = false
    private(set) var isConnected: Bool = false

    private init() {
        if #available(iOS 12.0, macOS 10.14, *) {
            let monitor = NWPathMonitor()
            monitor.pathUpdateHandler = { [weak self] path in
                guard let self = self else { return }
                self.isConnected = path.status == .satisfied
                self.isWiFi = path.usesInterfaceType(.wifi)
                self.isCellular = path.usesInterfaceType(.cellular)
            }
            monitor.start(queue: queue)
        } else {
            print("⚠️ NWPathMonitor not available on this OS version")
        }
    }
}

