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
    
    /// Configure the interceptor with full configuration
    /// - Parameter config: MyBurpConfiguration with all settings
    public static func configure(_ config: MyBurpConfiguration) {
        NetworkInterceptor.shared.configure(config)
    }
    
    /// Configure connection to desktop server (simplified)
    /// - Parameters:
    ///   - serverURL: URL of the desktop server (e.g., http://localhost:8080)
    ///   - mode: Interception mode (passive, intercept requests, etc.)
    public static func configureServer(url: URL, mode: InterceptMode = .passive) {
        var config = NetworkInterceptor.shared.configuration
        config.serverURL = url
        config.interceptMode = mode
        NetworkInterceptor.shared.configure(config)
    }
    
    /// Configure connection to desktop server (legacy, deprecated)
    /// - Parameters:
    ///   - serverURL: URL of the desktop server (e.g., http://localhost:8080)
    ///   - enabled: Whether to send intercepted data to server
    @available(*, deprecated, message: "Use configureServer(url:mode:) instead")
    public static func configureServer(url: URL, enabled: Bool) {
        var config = NetworkInterceptor.shared.configuration
        config.serverURL = enabled ? url : nil
        NetworkInterceptor.shared.configure(config)
    }
    
    /// Load configuration from xcconfig/Info.plist and start
    public static func startWithConfiguration() {
        let config = MyBurpConfiguration.loadFromEnvironment()
        NetworkInterceptor.shared.configure(config)
        NetworkInterceptor.shared.startIntercepting()
    }
    
    /// Get all intercepted network transactions
    public static func getTransactions() -> [NetworkTransaction] {
        return NetworkInterceptor.shared.getTransactions()
    }
    
    /// Clear all recorded transactions
    public static func clearTransactions() {
        NetworkInterceptor.shared.clearTransactions()
    }
    
    /// Get current configuration
    public static func getConfiguration() -> MyBurpConfiguration {
        return NetworkInterceptor.shared.configuration
    }
}
