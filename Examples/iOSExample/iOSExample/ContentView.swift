//
//  ContentView.swift
//  iOSExample
//
//  Created by Deepak on 16/08/25.
//

import SwiftUI
import Datablit

struct ContentView: View {
    @State private var eventName: String = ""
    @State private var propertyKey: String = ""
    @State private var propertyValue: String = ""
    @State private var customProperties: [String: String] = [:]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Datablit SDK Demo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Test analytics tracking and user identification")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ActionButton(
                                title: "Track Page View",
                                icon: "eye",
                                action: {
                                    trackEvent("Page Viewed", properties: ["page": "main"])
                                }
                            )
                            
                            ActionButton(
                                title: "Track Button Click",
                                icon: "hand.tap",
                                action: {
                                    trackEvent("Button Clicked", properties: ["button": "demo"])
                                }
                            )
                            
                            ActionButton(
                                title: "Track Purchase",
                                icon: "cart",
                                action: {
                                    trackEvent("Purchase Completed", properties: [
                                        "productId": "demo-product",
                                        "amount": "29.99",
                                        "currency": "USD"
                                    ])
                                }
                            )
                            
                            ActionButton(
                                title: "Manual Flush",
                                icon: "arrow.up.circle",
                                action: {
                                    Datablit.shared.flush()
                                    showAlert("Events flushed to server!")
                                }
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Custom Event Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Event")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("Event Name", text: $eventName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                TextField("Property Key", text: $propertyKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Property Value", text: $propertyValue)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Button("Add Property") {
                                    if !propertyKey.isEmpty && !propertyValue.isEmpty {
                                        customProperties[propertyKey] = propertyValue
                                        propertyKey = ""
                                        propertyValue = ""
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Clear Properties") {
                                    customProperties.removeAll()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                            
                            if !customProperties.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Properties:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(Array(customProperties.keys.sorted()), id: \.self) { key in
                                        Text("\(key): \(customProperties[key] ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Button("Track Custom Event") {
                                if !eventName.isEmpty {
                                    trackEvent(eventName, properties: customProperties)
                                    eventName = ""
                                    customProperties.removeAll()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(eventName.isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    
                    // User Identification Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("User Identification")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Button("Update User Traits") {
                                Datablit.shared.identify(
                                    userId: "demo-user-123",
                                    traits: [
                                        "name": "Updated Demo User",
                                        "email": "updated@datablit.com",
                                        "plan": "premium",
                                        "lastUpdated": Date().timeIntervalSince1970
                                    ]
                                )
                                showAlert("User traits updated!")
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Identify with Custom Struct") {
                                struct UserTraits: Codable {
                                    let name: String
                                    let email: String
                                    let plan: String
                                    let signupDate: Date
                                }
                                
                                let traits = UserTraits(
                                    name: "Struct User",
                                    email: "struct@datablit.com",
                                    plan: "enterprise",
                                    signupDate: Date()
                                )
                                
                                Datablit.shared.identify(userId: "struct-user-456", traits: traits)
                                showAlert("User identified with custom struct!")
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Status Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SDK Status")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            StatusRow(title: "SDK Initialized", value: "✅ Yes")
                            StatusRow(title: "User Identified", value: "✅ Yes")
                            StatusRow(title: "Lifecycle Tracking", value: "✅ Enabled")
                            StatusRow(title: "Network Status", value: NetworkStatus.shared.isConnected ? "✅ Connected" : "❌ Disconnected")
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Datablit Demo")
            .alert("Datablit SDK", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func trackEvent(_ eventName: String, properties: [String: String] = [:]) {
        // Convert string properties to appropriate types
        var convertedProperties: [String: Any] = [:]
        
        for (key, value) in properties {
            // Try to convert to number if possible
            if let intValue = Int(value) {
                convertedProperties[key] = intValue
            } else if let doubleValue = Double(value) {
                convertedProperties[key] = doubleValue
            } else if value.lowercased() == "true" || value.lowercased() == "false" {
                convertedProperties[key] = value.lowercased() == "true"
            } else {
                convertedProperties[key] = value
            }
        }
        
        Datablit.shared.track(eventName: eventName, properties: convertedProperties)
        showAlert("Event '\(eventName)' tracked successfully!")
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ContentView()
}
