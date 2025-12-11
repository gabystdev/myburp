import Foundation

/// Public API for MyBurp network interceptor
public enum MyBurp {
    
    /// Start intercepting network requests
    /// Call this early in your app's lifecycle (e.g., in AppDelegate or App struct)
    public static func start() {
        NetworkInterceptor.shared.startIntercepting()
    }
    
    /// Stop intercepting network requests
    public static func stop() {
        NetworkInterceptor.shared.stopIntercepting()
    }
    
    /// Configure connection to desktop server
    /// - Parameters:
    ///   - serverURL: URL of the desktop server (e.g., http://localhost:8080)
    ///   - enabled: Whether to send intercepted data to server
    public static func configureServer(url: URL, enabled: Bool = true) {
        NetworkInterceptor.shared.configureServer(url: url, enabled: enabled)
    }
    
    /// Get all intercepted network transactions
    public static func getTransactions() -> [NetworkTransaction] {
        return NetworkInterceptor.shared.getTransactions()
    }
    
    /// Clear all recorded transactions
    public static func clearTransactions() {
        NetworkInterceptor.shared.clearTransactions()
    }
}
