import SwiftUI
import Foundation
import SystemConfiguration
import Network
#if canImport(UIKit)
import UIKit
#endif

public final class Datablit : @unchecked Sendable{
    public static let shared = Datablit()

    private var endpoint: String = ""
    private var apiBaseURL: String = ""
    private var apiKey: String = ""
    private var anonymousId: String = UUID().uuidString
    private var userId: String?
    private var context: [String: AnyCodable] = [:]
    private var enableDebugLogs: Bool = false

    private var queue: [Event] = []
    private var flushAt = 20
    private var flushInterval: TimeInterval = 30
    private var timer: Timer?

    private let queueDispatch = DispatchQueue(label: "com.sdk.message.queue")

    private init() {}

    @MainActor
    public func initialize(
        apiKey: String,
        apiBaseURL: String = "https://console.datablit.com",
        endpoint: String = "https://event.datablit.com/v1/batch",
        flushAt: Int = 20,
        flushInterval: TimeInterval = 30.0,
        trackApplicationLifecycleEvents: Bool = false,
        enableDebugLogs: Bool = false
    ) {
        self.apiKey = apiKey
        self.apiBaseURL = apiBaseURL
        self.endpoint = endpoint
        self.flushAt = flushAt
        self.flushInterval = flushInterval
        self.enableDebugLogs = enableDebugLogs

        self.anonymousId = loadOrGenerateAnonymousId()
        self.userId = UserDefaults.standard.string(forKey: "sdk_user_id")
        setupContext()

        if trackApplicationLifecycleEvents {
            setupLifecycleTracking()
        }

        startFlushTimer()
    }

    private func debugLog(_ message: String) {
        if enableDebugLogs {
            print(message)
        }
    }
    
    private func errorLog(_ message: String) {
        print(message)
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
            errorLog("❌ Failed to encode encodable traits")
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
            errorLog("❌ Failed to encode encodable properties")
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

            guard let url = URL(string: self.endpoint),
                  let data = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
                self.errorLog("❌ Invalid URL or payload")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(self.apiKey, forHTTPHeaderField: "apiKey")
            request.httpBody = data

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    self.errorLog("❌ Flush failed: \(error.localizedDescription)")
                    self.queueDispatch.async {
                        self.queue = batch + self.queue
                    }
                    return
                }

                if let response = response as? HTTPURLResponse {
                    self.debugLog("✅ Status: \(response.statusCode)")
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
                "name": "datablit-swift",
                "version": "1.0.0"
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
        errorLog("❌ setupContext(): UIKit not available. Skipping context population.")
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








