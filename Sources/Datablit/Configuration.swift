import Foundation

public class Configuration {
    // Properties to hold the configuration values
    var writeKey: String
    var endpoint: String = "http://localhost:8080/v1/batch"
    var flushAt: Int = 1
    var flushInterval: Double = 30
    var trackApplicationLifecycleEvents: Bool = false
    var enableDebugLogs: Bool = false
    
    // Initializer for setting the required `writeKey`
    public init(writeKey: String) {
        self.writeKey = writeKey
    }
    
    @discardableResult
    public func endpoint(_ endpoint: String) -> Configuration {
        self.endpoint = endpoint
        return self
    }
    
    // Method to enable/disable automatic tracking of application lifecycle events
    @discardableResult
    public func trackApplicationLifecycleEvents(_ enable: Bool) -> Configuration {
        self.trackApplicationLifecycleEvents = enable
        return self
    }
    
    // Method to set the number of events to accumulate before flushing
    @discardableResult
    public func flushAt(_ count: Int) -> Configuration {
        self.flushAt = count
        return self
    }
    
    // Method to set the flush interval in seconds
    @discardableResult
    public func flushInterval(_ interval: Double) -> Configuration {
        self.flushInterval = interval
        return self
    }
}
