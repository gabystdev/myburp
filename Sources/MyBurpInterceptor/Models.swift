import Foundation

/// Represents a captured HTTP request
public struct RequestModel: Codable, Identifiable {
    public let id: UUID
    public var url: String
    public var method: String
    public var headers: [String: String]
    public var body: Data?
    public let timestamp: Date
    
    public init(
        id: UUID = UUID(),
        url: String,
        method: String,
        headers: [String: String],
        body: Data?,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.timestamp = timestamp
    }
    
    /// Creates a mutable copy of the request
    public func mutableCopy() -> RequestModel {
        return RequestModel(
            id: id,
            url: url,
            method: method,
            headers: headers,
            body: body,
            timestamp: timestamp
        )
    }
}

/// Represents a captured HTTP response
public struct ResponseModel: Codable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public var statusCode: Int
    public var headers: [String: String]
    public var body: Data?
    public let timestamp: Date
    public let duration: TimeInterval
    
    public init(
        id: UUID = UUID(),
        requestId: UUID,
        statusCode: Int,
        headers: [String: String],
        body: Data?,
        timestamp: Date = Date(),
        duration: TimeInterval
    ) {
        self.id = id
        self.requestId = requestId
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
        self.timestamp = timestamp
        self.duration = duration
    }
    
    /// Creates a mutable copy of the response
    public func mutableCopy() -> ResponseModel {
        return ResponseModel(
            id: id,
            requestId: requestId,
            statusCode: statusCode,
            headers: headers,
            body: body,
            timestamp: timestamp,
            duration: duration
        )
    }
}

/// Represents a complete HTTP transaction (request + response)
public struct NetworkTransaction: Codable, Identifiable {
    public let id: UUID
    public var request: RequestModel
    public var response: ResponseModel?
    public var state: TransactionState
    public var modified: Bool
    
    public init(
        id: UUID = UUID(),
        request: RequestModel,
        response: ResponseModel? = nil,
        state: TransactionState = .completed,
        modified: Bool = false
    ) {
        self.id = id
        self.request = request
        self.response = response
        self.state = state
        self.modified = modified
    }
}

/// State of a transaction in the interception flow
public enum TransactionState: String, Codable {
    case pending = "pending"           // Waiting for server approval
    case approved = "approved"         // Approved, will be sent
    case rejected = "rejected"         // Rejected, will fail
    case completed = "completed"       // Already completed (passive mode)
    case responsePending = "response_pending"  // Response intercepted, waiting for approval
}

/// Request for approval/modification from desktop server
public struct InterceptRequest: Codable {
    public let transactionId: UUID
    public let request: RequestModel
    public let timestamp: Date
    
    public init(transactionId: UUID, request: RequestModel, timestamp: Date = Date()) {
        self.transactionId = transactionId
        self.request = request
        self.timestamp = timestamp
    }
}

/// Response from desktop server with approval/modification
public struct InterceptResponse: Codable {
    public let transactionId: UUID
    public let action: InterceptAction
    public let modifiedRequest: RequestModel?
    public let modifiedResponse: ResponseModel?
    
    public init(
        transactionId: UUID,
        action: InterceptAction,
        modifiedRequest: RequestModel? = nil,
        modifiedResponse: ResponseModel? = nil
    ) {
        self.transactionId = transactionId
        self.action = action
        self.modifiedRequest = modifiedRequest
        self.modifiedResponse = modifiedResponse
    }
}

/// Action to take on an intercepted request/response
public enum InterceptAction: String, Codable {
    case forward = "forward"           // Send original
    case forwardModified = "forward_modified"  // Send modified version
    case drop = "drop"                 // Drop the request
    case respondWith = "respond_with"  // Respond without sending to server
}

/// Configuration for MyBurp interceptor
public struct MyBurpConfiguration: Codable {
    public var serverURL: URL?
    public var interceptMode: InterceptMode
    public var timeout: TimeInterval
    public var autoApprove: Bool
    
    public init(
        serverURL: URL? = nil,
        interceptMode: InterceptMode = .passive,
        timeout: TimeInterval = 30.0,
        autoApprove: Bool = false
    ) {
        self.serverURL = serverURL
        self.interceptMode = interceptMode
        self.timeout = timeout
        self.autoApprove = autoApprove
    }
    
    /// Load configuration from xcconfig or Info.plist
    public static func loadFromEnvironment() -> MyBurpConfiguration {
        var config = MyBurpConfiguration()
        
        // Try to load from Info.plist
        if let serverURLString = Bundle.main.object(forInfoDictionaryKey: "MyBurpServerURL") as? String,
           let serverURL = URL(string: serverURLString) {
            config.serverURL = serverURL
        }
        
        if let modeString = Bundle.main.object(forInfoDictionaryKey: "MyBurpInterceptMode") as? String,
           let mode = InterceptMode(rawValue: modeString) {
            config.interceptMode = mode
        }
        
        if let timeout = Bundle.main.object(forInfoDictionaryKey: "MyBurpTimeout") as? TimeInterval {
            config.timeout = timeout
        }
        
        return config
    }
}

/// Mode of operation for the interceptor
public enum InterceptMode: String, Codable {
    case passive = "passive"           // Just capture, don't block
    case interceptRequests = "intercept_requests"  // Block and wait for approval on requests
    case interceptResponses = "intercept_responses" // Block and wait for approval on responses
    case interceptAll = "intercept_all"  // Block on both requests and responses
}
