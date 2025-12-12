import XCTest
@testable import MyBurpInterceptor

final class MyBurpInterceptorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        NetworkInterceptor.shared.clearTransactions()
    }
    
    func testNetworkInterceptorInitialization() {
        let interceptor = NetworkInterceptor.shared
        XCTAssertNotNil(interceptor)
        XCTAssertEqual(interceptor.getTransactions().count, 0)
    }
    
    func testRequestModelCreation() {
        let request = RequestModel(
            url: "https://api.example.com/test",
            method: "GET",
            headers: ["Content-Type": "application/json"],
            body: nil
        )
        
        XCTAssertEqual(request.url, "https://api.example.com/test")
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.headers["Content-Type"], "application/json")
        XCTAssertNil(request.body)
    }
    
    func testResponseModelCreation() {
        let requestId = UUID()
        let response = ResponseModel(
            requestId: requestId,
            statusCode: 200,
            headers: ["Content-Type": "application/json"],
            body: nil,
            duration: 0.5
        )
        
        XCTAssertEqual(response.requestId, requestId)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers["Content-Type"], "application/json")
        XCTAssertEqual(response.duration, 0.5)
    }
    
    func testTransactionCreation() {
        let request = RequestModel(
            url: "https://api.example.com/test",
            method: "GET",
            headers: [:],
            body: nil
        )
        
        let transaction = NetworkTransaction(request: request)
        XCTAssertEqual(transaction.request.url, request.url)
        XCTAssertNil(transaction.response)
    }
    
    func testClearTransactions() {
        // Record a request
        let request = RequestModel(
            url: "https://api.example.com/test",
            method: "GET",
            headers: [:],
            body: nil
        )
        NetworkInterceptor.shared.recordRequest(request)
        
        // Wait a bit for async operation
        let expectation = XCTestExpectation(description: "Wait for recording")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify it was recorded
        XCTAssertGreaterThan(NetworkInterceptor.shared.getTransactions().count, 0)
        
        // Clear and verify
        NetworkInterceptor.shared.clearTransactions()
        XCTAssertEqual(NetworkInterceptor.shared.getTransactions().count, 0)
    }
    
    func testServerConfiguration() {
        let serverURL = URL(string: "http://localhost:8080")!
        MyBurp.configureServer(url: serverURL, mode: .passive)
        
        // Wait for async configuration to complete
        let expectation = XCTestExpectation(description: "Wait for configuration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify configuration was set
        let config = NetworkInterceptor.shared.configuration
        XCTAssertEqual(config.serverURL, serverURL)
        XCTAssertEqual(config.interceptMode, .passive)
    }
    
    func testInterceptModeConfiguration() {
        var config = MyBurpConfiguration()
        config.serverURL = URL(string: "http://localhost:8080")
        config.interceptMode = .interceptRequests
        config.timeout = 15.0
        
        MyBurp.configure(config)
        
        // Wait for async configuration to complete
        let expectation = XCTestExpectation(description: "Wait for configuration")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify configuration
        let savedConfig = NetworkInterceptor.shared.configuration
        XCTAssertEqual(savedConfig.interceptMode, .interceptRequests)
        XCTAssertEqual(savedConfig.timeout, 15.0)
    }
}
