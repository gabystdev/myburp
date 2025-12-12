import Foundation
import MyBurpInterceptor

/// Thread-safe transaction storage
final class TransactionStore {
    static let shared = TransactionStore()
    
    private var transactions: [NetworkTransaction] = []
    private var transactionMap: [UUID: Int] = [:]  // Maps ID to index
    private let queue = DispatchQueue(label: "com.myburp.server.store", attributes: .concurrent)
    
    private init() {}
    
    func add(_ transaction: NetworkTransaction) {
        queue.async(flags: .barrier) {
            self.transactions.append(transaction)
            self.transactionMap[transaction.id] = self.transactions.count - 1
        }
    }
    
    func update(_ transaction: NetworkTransaction) {
        queue.async(flags: .barrier) {
            if let index = self.transactionMap[transaction.id], index < self.transactions.count {
                self.transactions[index] = transaction
            }
        }
    }
    
    func getTransaction(id: UUID) -> NetworkTransaction? {
        return queue.sync {
            if let index = transactionMap[id], index < transactions.count {
                return transactions[index]
            }
            return nil
        }
    }
    
    func getAll() -> [NetworkTransaction] {
        return queue.sync {
            return transactions
        }
    }
    
    func getPending() -> [NetworkTransaction] {
        return queue.sync {
            return transactions.filter { $0.state == .pending || $0.state == .responsePending }
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.transactions.removeAll()
            self.transactionMap.removeAll()
        }
    }
    
    func count() -> Int {
        return queue.sync {
            return transactions.count
        }
    }
}
