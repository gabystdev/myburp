import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Main interceptor manager that coordinates network interception
public class NetworkInterceptor {
    
    public static let shared = NetworkInterceptor()
    
    private var transactions: [NetworkTransaction] = []
    private let queue = DispatchQueue(label: "com.myburp.interceptor", attributes: .concurrent)
    private var transactionMap: [UUID: Int] = [:]  // Maps request ID to transaction index
    
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
            self.transactionMap.removeAll()
        }
    }
    
    // MARK: - Internal Methods
    
    func recordRequest(_ request: RequestModel) {
        queue.async(flags: .barrier) {
            let transaction = NetworkTransaction(request: request)
            self.transactions.append(transaction)
            
            // Map request ID to transaction index for efficient lookup
            self.transactionMap[request.id] = self.transactions.count - 1
            
            // Send to desktop server if configured
            if self.isServerEnabled {
                self.sendToServer(transaction: transaction)
            }
        }
    }
    
    func recordResponse(_ response: ResponseModel, for requestID: UUID) {
        queue.async(flags: .barrier) {
            // Find the transaction by request ID
            guard let index = self.transactionMap[requestID],
                  index < self.transactions.count else {
                return
            }
            
            var updatedTransaction = self.transactions[index]
            updatedTransaction.response = response
            self.transactions[index] = updatedTransaction
            
            // Send updated transaction to server
            if self.isServerEnabled {
                self.sendToServer(transaction: updatedTransaction)
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
