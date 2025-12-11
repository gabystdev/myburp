import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Main interceptor manager that coordinates network interception
public class NetworkInterceptor {
    
    public static let shared = NetworkInterceptor()
    
    private var transactions: [NetworkTransaction] = []
    private let queue = DispatchQueue(label: "com.myburp.interceptor", attributes: .concurrent)
    private var requestMap: [String: RequestModel] = [:]
    
    /// Configuration for the desktop server
    public var serverURL: URL?
    public var isServerEnabled: Bool = false
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Start intercepting network requests
    public func startIntercepting() {
        _ = URLProtocol.registerClass(MyBurpURLProtocol.self)
    }
    
    /// Stop intercepting network requests
    public func stopIntercepting() {
        URLProtocol.unregisterClass(MyBurpURLProtocol.self)
    }
    
    /// Configure the desktop server connection
    public func configureServer(url: URL, enabled: Bool = true) {
        queue.async(flags: .barrier) {
            self.serverURL = url
            self.isServerEnabled = enabled
        }
    }
    
    /// Get all recorded transactions
    public func getTransactions() -> [NetworkTransaction] {
        return queue.sync {
            return transactions
        }
    }
    
    /// Clear all recorded transactions
    public func clearTransactions() {
        queue.async(flags: .barrier) {
            self.transactions.removeAll()
            self.requestMap.removeAll()
        }
    }
    
    // MARK: - Internal Methods
    
    func recordRequest(_ request: RequestModel) {
        queue.async(flags: .barrier) {
            // Store the request for later matching with response
            let key = "\(request.url)_\(request.timestamp.timeIntervalSince1970)"
            self.requestMap[key] = request
            
            let transaction = NetworkTransaction(request: request)
            self.transactions.append(transaction)
            
            // Send to desktop server if configured
            if self.isServerEnabled {
                self.sendToServer(transaction: transaction)
            }
        }
    }
    
    func recordResponse(_ response: ResponseModel) {
        queue.async(flags: .barrier) {
            // Try to match response with its request
            // In a real implementation, you'd have a better matching mechanism
            if let lastTransaction = self.transactions.last,
               lastTransaction.response == nil {
                var updatedTransaction = lastTransaction
                var updatedResponse = response
                updatedResponse = ResponseModel(
                    id: updatedResponse.id,
                    requestId: lastTransaction.request.id,
                    statusCode: updatedResponse.statusCode,
                    headers: updatedResponse.headers,
                    body: updatedResponse.body,
                    timestamp: updatedResponse.timestamp,
                    duration: updatedResponse.duration
                )
                updatedTransaction.response = updatedResponse
                
                if let index = self.transactions.firstIndex(where: { $0.id == lastTransaction.id }) {
                    self.transactions[index] = updatedTransaction
                }
                
                // Send updated transaction to server
                if self.isServerEnabled {
                    self.sendToServer(transaction: updatedTransaction)
                }
            }
        }
    }
    
    // MARK: - Server Communication
    
    private func sendToServer(transaction: NetworkTransaction) {
        guard let serverURL = serverURL else { return }
        
        var request = URLRequest(url: serverURL.appendingPathComponent("/intercept"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(transaction)
            
            // Send without intercepting this request
            let session = URLSession(configuration: .ephemeral)
            session.dataTask(with: request) { _, _, error in
                if let error = error {
                    print("MyBurp: Failed to send to server: \(error.localizedDescription)")
                }
            }.resume()
        } catch {
            print("MyBurp: Failed to encode transaction: \(error.localizedDescription)")
        }
    }
}
