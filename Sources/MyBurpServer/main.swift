import Foundation

print("""

╔═══════════════════════════════════════════════════════════════════╗
║                          MyBurp Server                            ║
║                   Network Traffic Interceptor                     ║
╚═══════════════════════════════════════════════════════════════════╝

""")

let port = getPort()
let server = MyBurpHTTPServer(port: port)

// Handle graceful shutdown
signal(SIGINT) { _ in
    print("\n\n👋 Shutting down gracefully...")
    // Note: We can't call server.stop() from signal handler safely
    // The server will be cleaned up on process exit
    exit(0)
}

do {
    try server.start()
} catch {
    print("❌ Failed to start server: \(error)")
    exit(1)
}

private func getPort() -> Int {
    if let portString = ProcessInfo.processInfo.environment["PORT"],
       let port = Int(portString) {
        return port
    }
    return 8080
}
