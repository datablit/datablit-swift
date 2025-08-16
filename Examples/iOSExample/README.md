# iOS Example App

This iOS example app demonstrates how to integrate and use the Datablit Swift SDK.

## Features Demonstrated

### 🚀 **SDK Initialization**

- Automatic SDK initialization on app launch
- Demo user identification
- Lifecycle event tracking enabled

### 📊 **Event Tracking**

- **Quick Actions**: Pre-defined events (Page View, Button Click, Purchase)
- **Custom Events**: Create and track custom events with properties
- **Manual Flush**: Manually trigger event sending to server

### 🆔 **User Identification**

- Update user traits with dictionary
- Identify users with custom Codable structs
- Real-time user identification

### 📱 **UI Features**

- Modern SwiftUI interface
- Interactive buttons for testing
- Real-time status display
- Property management for custom events

## How to Use

### 1. **Quick Testing**

Tap the quick action buttons to test common analytics events:

- **Track Page View** - Simulates a page view event
- **Track Button Click** - Simulates a button click event
- **Track Purchase** - Simulates a purchase completion event
- **Manual Flush** - Manually sends queued events to server

### 2. **Custom Events**

1. Enter an event name in the "Event Name" field
2. Add custom properties using the key-value fields
3. Tap "Track Custom Event" to send the event

### 3. **User Identification**

- **Update User Traits** - Updates the current user with new traits
- **Identify with Custom Struct** - Demonstrates using Codable structs for traits

### 4. **Status Monitoring**

The app shows real-time status of:

- SDK initialization
- User identification
- Lifecycle tracking
- Network connectivity

## Configuration

The app is configured with demo settings:

- **API Key**: `demo-api-key-12345`
- **API Base URL**: `https://console.datablit.com`
- **Endpoint**: `https://event.datablit.com/v1/batch`
- **Batch Size**: 10 events (smaller for demo)
- **Flush Interval**: 15 seconds (faster for demo)

## Expected Behavior

1. **App Launch**: SDK initializes and identifies demo user
2. **Event Tracking**: Events are queued and sent automatically
3. **Network**: Events are sent to the configured endpoint
4. **Lifecycle**: App lifecycle events are tracked automatically

## Troubleshooting

- **Events not sending**: Check network connectivity
- **Import errors**: Ensure Datablit library is properly linked
- **Build errors**: Verify iOS deployment target compatibility

## Next Steps

1. Replace the demo API key with your actual Datablit API key
2. Customize the endpoint URLs for your environment
3. Add more specific events for your use case
4. Implement user authentication flow
