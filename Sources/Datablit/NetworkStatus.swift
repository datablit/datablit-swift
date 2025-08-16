import Foundation
import Network

/// Monitors network connectivity status
public final class NetworkStatus: @unchecked Sendable {
    /// Shared instance for network status monitoring
    public static let shared = NetworkStatus()
    
    private let queue = DispatchQueue(label: "com.sdk.network.monitor")

    /// Indicates if WiFi is available
    public private(set) var isWiFi: Bool = false
    
    /// Indicates if cellular network is available
    public private(set) var isCellular: Bool = false
    
    /// Indicates if any network connection is available
    public private(set) var isConnected: Bool = false

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
