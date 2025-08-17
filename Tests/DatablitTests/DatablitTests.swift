import XCTest
@testable import Datablit

final class DatablitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        if #available(macOS 10.15, iOS 13.0, *) {
            // Initialize Datablit with test configuration
            Datablit.shared.initialize(
                apiKey: "test-api-key",
                apiBaseURL: "https://console.datablit.com",
                enableDebugLogs: true
            )
        }
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testEvalRuleRequestEncoding() throws {
        let request = EvalRuleRequest(
            key: "test-rule",
            userId: "user-123",
            params: [
                "param1": AnyCodable("value1"),
                "param2": AnyCodable(42),
                "param3": AnyCodable(true)
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["key"] as? String, "test-rule")
        XCTAssertEqual(json?["userId"] as? String, "user-123")
        
        let params = json?["params"] as? [String: Any]
        XCTAssertNotNil(params)
        XCTAssertEqual(params?["param1"] as? String, "value1")
        XCTAssertEqual(params?["param2"] as? Int, 42)
        XCTAssertEqual(params?["param3"] as? Bool, true)
    }
    
    func testEvalRuleResponseDecoding() throws {
        let json = """
        {
            "key": "test-rule",
            "userId": "user-123",
            "result": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(EvalRuleResponse.self, from: json)
        
        XCTAssertEqual(response.key, "test-rule")
        XCTAssertEqual(response.userId, "user-123")
        XCTAssertTrue(response.result)
    }
    
    func testEvalRuleResponseDecodingFalse() throws {
        let json = """
        {
            "key": "test-rule",
            "userId": "user-123",
            "result": false
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(EvalRuleResponse.self, from: json)
        
        XCTAssertEqual(response.key, "test-rule")
        XCTAssertEqual(response.userId, "user-123")
        XCTAssertFalse(response.result)
    }
    
    func testDatablitErrorLocalizedDescription() {
        let apiKeyError = DatablitError.apiKeyNotSet
        XCTAssertEqual(apiKeyError.localizedDescription, "API key is not set. Please initialize the SDK first.")
        
        let invalidURLError = DatablitError.invalidURL
        XCTAssertEqual(invalidURLError.localizedDescription, "Invalid URL for API request.")
        
        let invalidResponseError = DatablitError.invalidResponse
        XCTAssertEqual(invalidResponseError.localizedDescription, "Invalid response from server.")
        
        let encodingError = DatablitError.encodingError
        XCTAssertEqual(encodingError.localizedDescription, "Failed to encode request parameters.")
        
        let apiError = DatablitError.apiError(400, "Bad Request")
        XCTAssertEqual(apiError.localizedDescription, "API request failed: 400 - Bad Request")
    }
    
    func testHTTPStatusCodeExtension() {
        XCTAssertTrue(200.isSuccess)
        XCTAssertFalse(201.isSuccess)
        XCTAssertFalse(299.isSuccess)
        XCTAssertFalse(199.isSuccess)
        XCTAssertFalse(300.isSuccess)
        XCTAssertFalse(400.isSuccess)
        XCTAssertFalse(500.isSuccess)
    }
    
    func testRuleClassInitialization() {
        if #available(macOS 10.15, iOS 13.0, *) {
            let rule = Rule(apiKey: "test-api-key", apiBaseURL: "https://test.com")
            XCTAssertNotNil(rule)
        } else {
            // Skip test on older versions
            XCTAssertTrue(true)
        }
    }
    
    func testRuleClassWithDefaultBaseURL() {
        if #available(macOS 10.15, iOS 13.0, *) {
            let rule = Rule(apiKey: "test-api-key")
            XCTAssertNotNil(rule)
        } else {
            // Skip test on older versions
            XCTAssertTrue(true)
        }
    }
    
    func testDatablitRuleProperty() {
        if #available(macOS 10.15, iOS 13.0, *) {
            // Test that the rule property is accessible after initialization
            XCTAssertNotNil(Datablit.shared.rule)
        } else {
            // Skip test on older versions
            XCTAssertTrue(true)
        }
    }
    
    func testExperimentClassInitialization() {
        if #available(macOS 10.15, iOS 13.0, *) {
            let experiment = Experiment(apiKey: "test-api-key", apiBaseURL: "https://test.com")
            XCTAssertNotNil(experiment)
        } else {
            // Skip test on older versions
            XCTAssertTrue(true)
        }
    }
    
    func testExperimentClassWithDefaultBaseURL() {
        if #available(macOS 10.15, iOS 13.0, *) {
            let experiment = Experiment(apiKey: "test-api-key")
            XCTAssertNotNil(experiment)
        } else {
            // Skip test on older versions
            XCTAssertTrue(true)
        }
    }
    
    func testDatablitExperimentProperty() {
        if #available(macOS 10.15, iOS 13.0, *) {
            // Test that the experiment property is accessible after initialization
            XCTAssertNotNil(Datablit.shared.experiment)
        } else {
            // Skip test on older versions
            XCTAssertTrue(true)
        }
    }
    
    func testGetVariantRequestEncoding() throws {
        let request = GetVariantRequest(
            expId: "01K2JKVXR0J0ZWPX40XY8CAWBS",
            entityId: "user-123"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["expId"] as? String, "01K2JKVXR0J0ZWPX40XY8CAWBS")
        XCTAssertEqual(json?["entityId"] as? String, "user-123")
    }
    
    func testGetVariantResponseDecoding() throws {
        let json = """
        {
            "expId": "01K2JKVXR0J0ZWPX40XY8CAWBS",
            "entityId": "user-123",
            "variant": "control"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetVariantResponse.self, from: json)
        
        XCTAssertEqual(response.expId, "01K2JKVXR0J0ZWPX40XY8CAWBS")
        XCTAssertEqual(response.entityId, "user-123")
        XCTAssertEqual(response.variant, "control")
    }
    
    func testGetVariantResponseDecodingVariantA() throws {
        let json = """
        {
            "expId": "01K2JKVXR0J0ZWPX40XY8CAWBS",
            "entityId": "user-456",
            "variant": "variant_a"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(GetVariantResponse.self, from: json)
        
        XCTAssertEqual(response.expId, "01K2JKVXR0J0ZWPX40XY8CAWBS")
        XCTAssertEqual(response.entityId, "user-456")
        XCTAssertEqual(response.variant, "variant_a")
    }
}
