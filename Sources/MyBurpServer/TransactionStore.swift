import Foundation
import MyBurpInterceptor

/// Thread-safe transaction storage
final class TransactionStore {
    static let shared = TransactionStore()
    
    private var transactions: [NetworkTransaction] = []
    private let queue = DispatchQueue(label: "com.myburp.server.store", attributes: .concurrent)
    
    private init() {}
    
    func add(_ transaction: NetworkTransaction) {
        queue.async(flags: .barrier) {
            self.transactions.append(transaction)
        }
    }
    
    func getAll() -> [NetworkTransaction] {
        return queue.sync {
            return transactions
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.transactions.removeAll()
        }
    }
    
    func count() -> Int {
        return queue.sync {
            return transactions.count
        }
    }
}
