//
//  iOSExampleApp.swift
//  iOSExample
//
//  Created by Deepak on 16/08/25.
//

import SwiftUI
import Datablit

@main
struct iOSExampleApp: App {
    init() {
        // Initialize Datablit SDK
        Datablit.shared.initialize(
            apiKey: "eL01K2S8YPMA48TAC4HCGA77WWBP",
            apiBaseURL: "https://staging-console.datablit.com",
            endpoint: "https://staging-event.datablit.com/v1/batch",
            flushAt: 1, // Smaller batch size for demo
            flushInterval: 30.0, // Faster flush for demo
            trackApplicationLifecycleEvents: true
        )
        
        // Identify a demo user
        Datablit.shared.identify(
            userId: "demo-user-123",
            traits: [
                "name": "Demo User",
                "email": "demo@datablit.com",
                "plan": "demo",
                "appVersion": "1.0.0"
            ]
        )
        
        print("🚀 Datablit SDK initialized successfully!")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
