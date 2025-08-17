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
    
    // Rule evaluation state
    @State private var ruleKey: String = "fer"
    @State private var ruleUserId: String = "1"
    @State private var ruleParamKey: String = "os_name"
    @State private var ruleParamValue: String = "android"
    @State private var ruleParams: [String: String] = [:]
    @State private var ruleResult: String = ""
    @State private var isEvaluatingRule = false
    
    // Experiment state
    @State private var experimentId: String = "01K2JKVXR0J0ZWPX40XY8CAWBS"
    @State private var experimentUserId: String = "1"
    @State private var experimentResult: String = ""
    @State private var isGettingVariant = false
    
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
                        
                        Text("Test analytics tracking, user identification, and rule evaluation")
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
                    
                    // Rule Evaluation Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rule Evaluation")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("Rule Key", text: $ruleKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("User ID", text: $ruleUserId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            HStack {
                                TextField("Parameter Key", text: $ruleParamKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                TextField("Parameter Value", text: $ruleParamValue)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            HStack {
                                Button("Add Parameter") {
                                    if !ruleParamKey.isEmpty && !ruleParamValue.isEmpty {
                                        ruleParams[ruleParamKey] = ruleParamValue
                                        ruleParamKey = ""
                                        ruleParamValue = ""
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Clear Parameters") {
                                    ruleParams.removeAll()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                            
                            if !ruleParams.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Parameters:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    ForEach(Array(ruleParams.keys.sorted()), id: \.self) { key in
                                        Text("\(key): \(ruleParams[key] ?? "")")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Button("Evaluate Rule") {
                                Task {
                                    await evaluateRule()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(ruleKey.isEmpty || ruleUserId.isEmpty || isEvaluatingRule)
                            
                            if isEvaluatingRule {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Evaluating rule...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !ruleResult.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Result:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(ruleResult)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Experiment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Experiment Variants")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TextField("Experiment ID", text: $experimentId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            TextField("User ID", text: $experimentUserId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Get Variant") {
                                Task {
                                    await getExperimentVariant()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(experimentId.isEmpty || experimentUserId.isEmpty || isGettingVariant)
                            
                            if isGettingVariant {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Getting variant...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !experimentResult.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Result:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(experimentResult)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(6)
                                }
                                .padding(.horizontal)
                            }
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
    
    private func evaluateRule() async {
        isEvaluatingRule = true
        ruleResult = ""
        
        do {
            let result = try await Datablit.shared.rule.evalRule(
                key: ruleKey,
                userId: ruleUserId,
                params: ruleParams
            )
            
            await MainActor.run {
                ruleResult = """
                Rule: \(result.key)
                User: \(result.userId)
                Result: \(result.result ? "✅ True" : "❌ False")
                """
                isEvaluatingRule = false
            }
        } catch {
            await MainActor.run {
                ruleResult = "Error: \(error.localizedDescription)"
                isEvaluatingRule = false
            }
        }
    }
    
    private func getExperimentVariant() async {
        isGettingVariant = true
        experimentResult = ""
        
        do {
            let result = try await Datablit.shared.experiment.getVariant(
                expId: experimentId,
                entityId: experimentUserId
            )
            
            await MainActor.run {
                experimentResult = """
                Experiment: \(result.expId)
                User: \(result.entityId)
                Variant: \(result.variant)
                """
                isGettingVariant = false
            }
        } catch {
            await MainActor.run {
                experimentResult = "Error: \(error.localizedDescription)"
                isGettingVariant = false
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
