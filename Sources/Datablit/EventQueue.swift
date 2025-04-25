import Foundation

@MainActor
class EventQueue {
    private let config: Configuration
    private var events: [[String: Any]] = []
    private var timer: Timer?

    init(config: Configuration) {
        self.config = config
        startTimer()
    }

    func enqueue(event: String, properties: [String: Any]) {
        var payload: [String: Any] = [
            "event": event,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "properties": properties
        ]

        events.append(payload)

        if config.enableDebugLogs {
            print("[Analytics] Enqueued event: \(payload)")
        }

        if events.count >= config.flushAt {
            flush()
        }
    }

    func flush() {
        guard !events.isEmpty else { return }

        let batch = events
        events = []

        if config.enableDebugLogs {
            print("[Analytics] Flushing \(batch.count) events to \(config.endpoint)")
        }

        HTTPClient.post(url: config.endpoint, payload: ["batch": batch]) { success in
            if self.config.enableDebugLogs {
                print("[Analytics] Flush \(success ? "succeeded" : "failed")")
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: config.flushInterval, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }

    deinit {
        timer?.invalidate()
    }
}

