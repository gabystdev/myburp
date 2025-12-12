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
    private var pendingRequests: [UUID: DispatchSemaphore] = [:]  // Semaphores for blocking requests
    
    /// Configuration
    public var configuration: MyBurpConfiguration
    
    private init() {
        self.configuration = MyBurpConfiguration.loadFromEnvironment()
    }
    
    // MARK: - Public Methods
    
    /// Start intercepting network requests
    public func startIntercepting() {
        let success = URLProtocol.registerClass(MyBurpURLProtocol.self)
        if !success {
            print("MyBurp: Warning - Failed to register URLProtocol. It may already be registered.")
        }
    }
    
    /// Stop intercepting network requests
    public func stopIntercepting() {
        URLProtocol.unregisterClass(MyBurpURLProtocol.self)
    }
    
    /// Configure the interceptor
    public func configure(_ config: MyBurpConfiguration) {
        queue.async(flags: .barrier) {
            self.configuration = config
        }
    }
    
    /// Configure the desktop server connection (legacy method)
    @available(*, deprecated, message: "Use configure(_:) instead")
    public func configureServer(url: URL, enabled: Bool = true) {
        queue.async(flags: .barrier) {
            self.configuration.serverURL = url
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
    
    func recordRequest(_ request: RequestModel) -> RequestModel? {
        var finalRequest = request
        var shouldBlock = false
        
        queue.sync(flags: .barrier) {
            let state: TransactionState
            switch configuration.interceptMode {
            case .interceptRequests, .interceptAll:
                state = .pending
                shouldBlock = true
            case .passive, .interceptResponses:
                state = .completed
            }
            
            let transaction = NetworkTransaction(request: request, state: state)
            self.transactions.append(transaction)
            self.transactionMap[request.id] = self.transactions.count - 1
            
            // Send to desktop server if configured
            if let serverURL = configuration.serverURL {
                if shouldBlock {
                    // Create semaphore for blocking
                    let semaphore = DispatchSemaphore(value: 0)
                    self.pendingRequests[request.id] = semaphore
                    self.sendInterceptRequest(transaction: transaction, serverURL: serverURL)
                } else {
                    // Just send for logging
                    self.sendToServer(transaction: transaction, serverURL: serverURL)
                }
            }
        }
        
        // Block if needed and wait for approval
        if shouldBlock {
            let semaphore = queue.sync { pendingRequests[request.id] }
            
            if let semaphore = semaphore {
                // Wait for approval or timeout
                let timeout = DispatchTime.now() + configuration.timeout
                let result = semaphore.wait(timeout: timeout)
                
                queue.sync(flags: .barrier) {
                    pendingRequests.removeValue(forKey: request.id)
                }
                
                if result == .timedOut {
                    print("MyBurp: Request \(request.id) timed out, proceeding with original")
                    return request
                }
                
                // Get the possibly modified request
                let index = queue.sync { transactionMap[request.id] }
                if let index = index, index < queue.sync(execute: { transactions.count }) {
                    finalRequest = queue.sync { transactions[index].request }
                }
            }
        }
        
        return finalRequest
    }
    
    /// Approve and optionally modify a pending request
    public func approveRequest(_ requestId: UUID, modifiedRequest: RequestModel? = nil) {
        queue.async(flags: .barrier) {
            guard let index = self.transactionMap[requestId],
                  index < self.transactions.count else {
                return
            }
            
            var transaction = self.transactions[index]
            if let modified = modifiedRequest {
                transaction.request = modified
                transaction.modified = true
            }
            transaction.state = .approved
            self.transactions[index] = transaction
            
            // Signal the waiting request
            if let semaphore = self.pendingRequests[requestId] {
                semaphore.signal()
            }
        }
    }
    
    /// Reject a pending request
    public func rejectRequest(_ requestId: UUID) {
        queue.async(flags: .barrier) {
            guard let index = self.transactionMap[requestId],
                  index < self.transactions.count else {
                return
            }
            
            var transaction = self.transactions[index]
            transaction.state = .rejected
            self.transactions[index] = transaction
            
            // Signal the waiting request
            if let semaphore = self.pendingRequests[requestId] {
                semaphore.signal()
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
            updatedTransaction.state = .completed
            self.transactions[index] = updatedTransaction
            
            // Send updated transaction to server
            if let serverURL = self.configuration.serverURL {
                self.sendToServer(transaction: updatedTransaction, serverURL: serverURL)
            }
        }
    }
    
    // MARK: - Server Communication
    
    private func sendInterceptRequest(transaction: NetworkTransaction, serverURL: URL) {
        var request = URLRequest(url: serverURL.appendingPathComponent("/intercept-request"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = configuration.timeout
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let interceptRequest = InterceptRequest(
                transactionId: transaction.id,
                request: transaction.request
            )
            request.httpBody = try encoder.encode(interceptRequest)
            
            // Send without intercepting this request
            let session = URLSession(configuration: .ephemeral)
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("MyBurp: Failed to send intercept request to server: \(error.localizedDescription)")
                    // Auto-approve on error
                    self.approveRequest(transaction.request.id)
                    return
                }
                
                // Parse response
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let interceptResponse = try decoder.decode(InterceptResponse.self, from: data)
                        
                        switch interceptResponse.action {
                        case .forward:
                            self.approveRequest(transaction.request.id)
                        case .forwardModified:
                            if let modified = interceptResponse.modifiedRequest {
                                self.approveRequest(transaction.request.id, modifiedRequest: modified)
                            } else {
                                self.approveRequest(transaction.request.id)
                            }
                        case .drop:
                            self.rejectRequest(transaction.request.id)
                        case .respondWith:
                            // TODO: Handle custom response
                            self.rejectRequest(transaction.request.id)
                        }
                    } catch {
                        print("MyBurp: Failed to decode intercept response: \(error.localizedDescription)")
                        self.approveRequest(transaction.request.id)
                    }
                }
            }.resume()
        } catch {
            print("MyBurp: Failed to encode intercept request: \(error.localizedDescription)")
            self.approveRequest(transaction.request.id)
        }
    }
    
    private func sendToServer(transaction: NetworkTransaction, serverURL: URL) {
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
