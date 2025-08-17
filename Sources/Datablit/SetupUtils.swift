import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Setup Utilities

/// Utility functions for setting up Datablit SDK context and lifecycle tracking
@available(macOS 10.15, iOS 13.0, *)
internal final class SetupUtils {
    
    /// Sets up the context information for the SDK
    /// - Parameter context: Reference to the context dictionary to populate
    @MainActor
    static func setupContext(_ context: inout [String: AnyCodable]) {
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

        context = [
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
        print("❌ setupContext(): UIKit not available. Skipping context population.")
        #endif
    }
    
    /// Sets up lifecycle tracking for the application
    /// - Parameter datablit: Reference to the Datablit instance for tracking events
    @MainActor
    static func setupLifecycleTracking(_ datablit: Datablit) {
        #if canImport(UIKit)
        let center = NotificationCenter.default
        center.addObserver(datablit, selector: #selector(datablit.appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(datablit, selector: #selector(datablit.appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(datablit, selector: #selector(datablit.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(datablit, selector: #selector(datablit.appDidFinishLaunching), name: UIApplication.didFinishLaunchingNotification, object: nil)
        #endif
    }
}
