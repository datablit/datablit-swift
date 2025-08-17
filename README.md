# Datablit Swift SDK

A Swift library for tracking analytics events and user identification with Datablit.

## Features

- 🚀 **Easy Integration** - Simple setup with just a few lines of code
- 📱 **iOS Support** - Full iOS integration with lifecycle event tracking
- 🔄 **Automatic Batching** - Events are automatically batched and sent to the server
- 🆔 **User Identification** - Track user traits and properties
- 📊 **Event Tracking** - Track custom events with properties
- 🌐 **Network Monitoring** - Automatic network status detection
- 🧵 **Thread Safe** - Built with concurrency safety in mind

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/analytics-swift.git", from: "1.0.0")
]
```

Or add it directly in Xcode:

1. Go to File → Add Package Dependencies
2. Enter the repository URL
3. Select the version you want to use

## Quick Start

### 1. Initialize the SDK

```swift
import Datablit

// Initialize with your API key
Datablit.shared.initialize(
    apiKey: "your-api-key-here",
    apiBaseURL: "https://console.datablit.com", // Optional, defaults to this URL
    endpoint: "https://event.datablit.com/v1/batch", // Optional, defaults to this URL
    flushAt: 20, // Optional, number of events to batch before sending
    flushInterval: 30.0, // Optional, seconds between automatic flushes
    trackApplicationLifecycleEvents: true, // Optional, track app lifecycle events
    enableDebugLogs: false // Optional, enable debug logging (defaults to false)
)
```

### 2. Identify Users

```swift
// Identify a user with basic traits
Datablit.shared.identify(
    userId: "user123",
    traits: [
        "name": "John Doe",
        "email": "john@example.com",
        "plan": "premium"
    ]
)

// Or use a custom struct
struct UserTraits: Codable {
    let name: String
    let email: String
    let plan: String
    let signupDate: Date
}

let traits = UserTraits(
    name: "John Doe",
    email: "john@example.com",
    plan: "premium",
    signupDate: Date()
)

Datablit.shared.identify(userId: "user123", traits: traits)
```

### 3. Track Events

```swift
// Track a simple event
Datablit.shared.track(eventName: "Button Clicked")

// Track an event with properties
Datablit.shared.track(
    eventName: "Purchase Completed",
    properties: [
        "productId": "prod_123",
        "amount": 29.99,
        "currency": "USD"
    ]
)

// Or use a custom struct for properties
struct PurchaseProperties: Codable {
    let productId: String
    let amount: Double
    let currency: String
    let category: String
}

let properties = PurchaseProperties(
    productId: "prod_123",
    amount: 29.99,
    currency: "USD",
    category: "electronics"
)

Datablit.shared.track(eventName: "Purchase Completed", properties: properties)
```

### 4. Manual Flush

```swift
// Manually flush events to the server
Datablit.shared.flush()
```

### 5. Rule Evaluation

**Note:** Rule evaluation is available on iOS 13.0+ / macOS 10.15+. For optimal performance with newer URLSession APIs, iOS 15.0+ / macOS 12.0+ is recommended.

```swift
// Evaluate a rule with basic parameters
let ruleResult = try await Datablit.shared.rule.evalRule(
    key: "feature-flag",
    userId: "user123",
    params: [
        "os_name": "ios",
        "app_version": "1.0.0"
    ]
)

if ruleResult.result {
    print("Rule evaluated to true")
} else {
    print("Rule evaluated to false")
}
```

### 6. Experiment Variants

**Note:** Experiment functionality is available on iOS 13.0+ / macOS 10.15+. For optimal performance with newer URLSession APIs, iOS 15.0+ / macOS 12.0+ is recommended.

```swift
// Get experiment variant for a user
let variant = try await Datablit.shared.experiment.getVariant(
    expId: "01K2JKVXR0J0ZWPX40XY8CAWBS",
    entityId: "user123"
)

print("User is in variant:", variant.variant) // "control", "variant_a", etc.

// Handle different variants
switch variant.variant {
case "control":
    // Show control version
    break
case "variant_a":
    // Show variant A
    break
case "variant_b":
    // Show variant B
    break
default:
    // Handle unknown variant
    break
}
```

## API Reference

### Datablit Class

The main class for interacting with the Datablit SDK.

#### Properties

- `shared` - Singleton instance of the Datablit class

#### Methods

##### `initialize(apiKey:apiBaseURL:endpoint:flushAt:flushInterval:trackApplicationLifecycleEvents:enableDebugLogs:)`

Initializes the SDK with the provided configuration.

- **Parameters:**
  - `apiKey` (String): Your Datablit API key
  - `apiBaseURL` (String, optional): Base URL for the Datablit console (defaults to `https://console.datablit.com`)
  - `endpoint` (String, optional): Custom endpoint URL (defaults to `https://event.datablit.com/v1/batch`)
  - `flushAt` (Int, optional): Number of events to batch before sending (defaults to 20)
  - `flushInterval` (TimeInterval, optional): Seconds between automatic flushes (defaults to 30.0)
  - `trackApplicationLifecycleEvents` (Bool, optional): Whether to track app lifecycle events (defaults to false)
  - `enableDebugLogs` (Bool, optional): Whether to enable debug logging (defaults to false)

##### `identify(userId:traits:)`

Identifies a user with the given traits.

- **Parameters:**
  - `userId` (String): Unique identifier for the user
  - `traits` (Dictionary or Codable object): User traits and properties

##### `track(eventName:properties:)`

Tracks an event with optional properties.

- **Parameters:**
  - `eventName` (String): Name of the event to track
  - `properties` (Dictionary or Codable object, optional): Event properties

##### `flush()`

Manually flushes queued events to the server.

### Rule Class

A separate class for evaluating rules with Datablit.

#### Properties

- `apiKey` - The Datablit API key
- `apiBaseURL` - The base URL for the Datablit console

#### Methods

##### `init(apiKey:apiBaseURL:)`

Initializes a new Rule instance.

- **Parameters:**
  - `apiKey` (String): Your Datablit API key
  - `apiBaseURL` (String, optional): Base URL for the Datablit console (defaults to `https://console.datablit.com`)

##### `evalRule(key:userId:params:)`

Evaluates a rule for a given user and context.

- **Parameters:**
  - `key` (String): The rule key to evaluate
  - `userId` (String): The user ID for the evaluation
  - `params` (Dictionary, optional): Parameters for the rule evaluation
- **Returns:** `EvalRuleResponse` - The evaluation result with key, userId, and result

##### `getVariant(expId:entityId:)`

Gets the experiment variant for a user.

- **Parameters:**
  - `expId` (String): The experiment ID
  - `entityId` (String): The entity ID (user ID)
- **Returns:** `GetVariantResponse` - The experiment variant response with expId, entityId, and variant

### Experiment Class

A separate class for managing experiments with Datablit.

#### Properties

- `apiKey` - The Datablit API key
- `apiBaseURL` - The base URL for the Datablit console

#### Methods

##### `init(apiKey:apiBaseURL:)`

Initializes a new Experiment instance.

- **Parameters:**
  - `apiKey` (String): Your Datablit API key
  - `apiBaseURL` (String, optional): Base URL for the Datablit console (defaults to `https://console.datablit.com`)

##### `getVariant(expId:entityId:)`

Gets the experiment variant for a user.

- **Parameters:**
  - `expId` (String): The experiment ID
  - `entityId` (String): The entity ID (user ID)
- **Returns:** `GetVariantResponse` - The experiment variant response with expId, entityId, and variant

### Rule Models

#### EvalRuleRequest

Request model for rule evaluation.

- **Properties:**
  - `key` (String): The rule key to evaluate
  - `userId` (String): The user ID for the evaluation
  - `params` ([String: AnyCodable]?, optional): Parameters for the rule evaluation

#### EvalRuleResponse

Response model for rule evaluation.

- **Properties:**
  - `key` (String): The rule key that was evaluated
  - `userId` (String): The user ID that was evaluated
  - `result` (Bool): The evaluation result (true/false)

#### GetVariantRequest

Request model for getting experiment variant.

- **Properties:**
  - `expId` (String): The experiment ID
  - `entityId` (String): The entity ID (user ID)

#### GetVariantResponse

Response model for getting experiment variant.

- **Properties:**
  - `expId` (String): The experiment ID
  - `entityId` (String): The entity ID (user ID)
  - `variant` (String): The variant assigned to the user

### Event Types

The SDK automatically tracks the following application lifecycle events when enabled:

- `Application Launched` - When the app finishes launching
- `Application Active` - When the app becomes active
- `Application Foreground` - When the app enters the foreground
- `Application Backgrounded` - When the app enters the background

## Architecture

The library is organized into several focused modules:

### Core Files

- **`Datablit.swift`** - Main SDK class with initialization and tracking methods
- **`Rule.swift`** - Rule evaluation functionality with API integration and models (`EvalRuleRequest`, `EvalRuleResponse`)
- **`Experiment.swift`** - Experiment functionality with API integration and models (`GetVariantRequest`, `GetVariantResponse`)
- **`NetworkClient.swift`** - Shared network client for HTTP requests
- **`SetupUtils.swift`** - Utility functions for context setup and lifecycle tracking
- **`Models.swift`** - Event types and data models (`Event`, `EventType`)
- **`AnyCodable.swift`** - Dynamic JSON value handling for flexible property types
- **`NetworkStatus.swift`** - Network connectivity monitoring

### Key Features

- **Thread Safety**: All types conform to `Sendable` for safe concurrent usage
- **Automatic Batching**: Events are queued and sent in batches for efficiency
- **Network Resilience**: Failed requests are retried automatically
- **Type Safety**: Full Swift type safety with optional Codable support

## Configuration

### Default Settings

- **API Base URL**: `https://console.datablit.com`
- **Endpoint**: `https://event.datablit.com/v1/batch`
- **Batch Size**: 20 events
- **Flush Interval**: 30 seconds
- **Lifecycle Tracking**: Disabled by default
- **Debug Logging**: Disabled by default

### Custom Configuration

You can customize the SDK behavior by passing different parameters to the `initialize` method:

```swift
Datablit.shared.initialize(
    apiKey: "your-api-key",
    apiBaseURL: "https://your-custom-console.com",
    endpoint: "https://your-custom-endpoint.com/v1/batch",
    flushAt: 50, // Larger batches
    flushInterval: 60.0, // Longer intervals
    trackApplicationLifecycleEvents: true,
    enableDebugLogs: true // Enable debug logging for development
)
```

## Debug Logging

The SDK provides configurable debug logging to help with development and troubleshooting:

- **Error Messages**: Critical errors (❌) are always logged regardless of the debug setting
- **Debug Messages**: Informational messages (✅) are only logged when `enableDebugLogs` is `true`
- **Status Codes**: HTTP response status codes are logged when debug logging is enabled
- **Network Events**: Network request details are logged when debug logging is enabled

### Example Debug Output

When `enableDebugLogs: true` is set, you'll see output like:

```
✅ Status: 200
```

When errors occur, you'll always see:

```
❌ Flush failed: Network connection lost
❌ Failed to encode encodable traits
```

## Error Handling

The SDK handles errors gracefully:

- Network failures trigger automatic retries
- Invalid events are logged but don't crash the app
- Encoding failures are logged with descriptive messages

## Requirements

- iOS 13.0+ / macOS 10.15+
- Swift 5.0+
- Xcode 12.0+

**Note:** The Datablit SDK requires iOS 13.0+ / macOS 10.15+ due to async/await support. Rule evaluation functionality includes fallback support for older URLSession APIs on iOS 15.0+ / macOS 12.0+.

## License

[Add your license information here]

## Support

For support and questions, please contact [your support email] or create an issue in this repository.
