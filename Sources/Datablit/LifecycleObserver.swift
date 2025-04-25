//import UIKit
//
//class LifecycleObserver {
//    private var firstLaunch = true
//
//    init() {
//        NotificationCenter.default.addObserver(self,
//            selector: #selector(appDidBecomeActive),
//            name: UIApplication.didBecomeActiveNotification,
//            object: nil)
//
//        NotificationCenter.default.addObserver(self,
//            selector: #selector(appWillResignActive),
//            name: UIApplication.willResignActiveNotification,
//            object: nil)
//
//        trackInstallOrUpdate()
//    }
//
//    private func trackInstallOrUpdate() {
//        let defaults = UserDefaults.standard
//        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
//        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
//        let prevVersion = defaults.string(forKey: "version")
//        let prevBuild = defaults.string(forKey: "build")
//
//        if prevVersion == nil {
//            Analytics.shared.track("Application Installed", properties: ["version": version, "build": build])
//        } else if prevVersion != version {
//            Analytics.shared.track("Application Updated", properties: [
//                "version": version,
//                "build": build,
//                "previous_version": prevVersion ?? "",
//                "previous_build": prevBuild ?? ""
//            ])
//        }
//
//        defaults.set(version, forKey: "version")
//        defaults.set(build, forKey: "build")
//    }
//
//    @objc private func appDidBecomeActive() {
//        Analytics.shared.track("Application Opened", properties: ["from_background": !firstLaunch])
//        firstLaunch = false
//    }
//
//    @objc private func appWillResignActive() {
//        Analytics.shared.track("Application Backgrounded")
//    }
//}
//
