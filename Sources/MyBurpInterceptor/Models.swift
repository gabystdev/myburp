import Foundation

/// Represents a captured HTTP request
public struct RequestModel: Codable, Identifiable {
    public let id: UUID
    public let url: String
    public let method: String
    public let headers: [String: String]
    public let body: Data?
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
}

/// Represents a captured HTTP response
public struct ResponseModel: Codable, Identifiable {
    public let id: UUID
    public let requestId: UUID
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
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
}

/// Represents a complete HTTP transaction (request + response)
public struct NetworkTransaction: Codable, Identifiable {
    public let id: UUID
    public let request: RequestModel
    public var response: ResponseModel?
    
    public init(id: UUID = UUID(), request: RequestModel, response: ResponseModel? = nil) {
        self.id = id
        self.request = request
        self.response = response
    }
}
