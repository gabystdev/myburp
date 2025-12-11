# MyBurp - iOS Network Interceptor + Desktop Server

A lightweight iOS network interceptor library similar to Wormholy, designed to capture and forward HTTP/HTTPS requests to a desktop application for inspection and modification.

## Features

- 🔍 **Network Interception**: Automatically intercept all HTTP/HTTPS requests made by your iOS app
- 📡 **Desktop Server**: NIO-based HTTP server for receiving intercepted traffic
- 🚀 **Simple API**: Easy to integrate with just a few lines of code
- 🧪 **Lightweight**: Minimal implementation without unnecessary overhead
- 📦 **Swift Package Manager**: Easy integration via SPM
- 🖥️ **REST API**: Query and manage intercepted transactions

## Architecture

MyBurp consists of two main components:

1. **iOS Interceptor Library**: Captures network traffic and sends it to a desktop server
2. **Desktop Server Application**: NIO-based HTTP server that receives and stores intercepted traffic

## Installation

### Swift Package Manager

Add MyBurp to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/gabystdev/myburp.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL: `https://github.com/gabystdev/myburp`
3. Select version requirements

## Usage

### Basic Setup

In your iOS app, start the interceptor early in your app's lifecycle:

```swift
import MyBurpInterceptor

// In your AppDelegate or SwiftUI App struct
@main
struct MyApp: App {
    init() {
        // Start intercepting network requests
        MyBurp.start()
        
        // Optional: Configure desktop server connection
        if let serverURL = URL(string: "http://localhost:8080") {
            MyBurp.configureServer(url: serverURL, enabled: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### UIKit Setup

For UIKit apps, add to your `AppDelegate`:

```swift
import UIKit
import MyBurpInterceptor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Start intercepting
        MyBurp.start()
        
        // Configure server (optional)
        if let serverURL = URL(string: "http://192.168.1.100:8080") {
            MyBurp.configureServer(url: serverURL, enabled: true)
        }
        
        return true
    }
}
```

### Access Intercepted Traffic

You can access intercepted network transactions programmatically:

```swift
// Get all intercepted transactions
let transactions = MyBurp.getTransactions()

for transaction in transactions {
    print("Request: \(transaction.request.method) \(transaction.request.url)")
    if let response = transaction.response {
        print("Response: \(response.statusCode)")
    }
}

// Clear all transactions
MyBurp.clearTransactions()
```

### Stop Intercepting

To stop intercepting network requests:

```swift
MyBurp.stop()
```

## How It Works

MyBurp uses iOS's `URLProtocol` mechanism to intercept network requests:

1. **URLProtocol Registration**: A custom `MyBurpURLProtocol` is registered with the URL loading system
2. **Request Interception**: All HTTP/HTTPS requests pass through the custom protocol
3. **Data Capture**: Request and response data is captured and stored
4. **Server Communication**: Intercepted data is optionally sent to a desktop server via HTTP POST
5. **Transparent Operation**: Original requests continue to execute normally

## Data Models

### RequestModel
```swift
public struct RequestModel {
    public let id: UUID
    public let url: String
    public let method: String
    public let headers: [String: String]
    public let body: Data?
    public let timestamp: Date
}
```

### ResponseModel
```swift
public struct ResponseModel {
    public let id: UUID
    public let requestId: UUID
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?
    public let timestamp: Date
    public let duration: TimeInterval
}
```

### NetworkTransaction
```swift
public struct NetworkTransaction {
    public let id: UUID
    public let request: RequestModel
    public var response: ResponseModel?
}
```

## Desktop Server Protocol

When enabled, MyBurp sends intercepted transactions to the configured desktop server via HTTP POST to `/intercept` endpoint:

```
POST /intercept
Content-Type: application/json

{
  "id": "UUID",
  "request": {
    "id": "UUID",
    "url": "https://api.example.com/users",
    "method": "GET",
    "headers": { ... },
    "body": null,
    "timestamp": "2024-01-01T00:00:00Z"
  },
  "response": {
    "id": "UUID",
    "requestId": "UUID",
    "statusCode": 200,
    "headers": { ... },
    "body": "base64_encoded_data",
    "timestamp": "2024-01-01T00:00:01Z",
    "duration": 0.5
  }
}
```

## Requirements

- iOS 14.0+ / macOS 11.0+
- Swift 5.9+
- Xcode 15.0+

## Desktop Server

### Running the Server

```bash
# Build and run
swift run MyBurpServer

# Or run the built binary
.build/debug/MyBurpServer
```

The server will start on port 8080 by default. You can customize the port:

```bash
PORT=9090 swift run MyBurpServer
```

### Server API

The server provides these endpoints:

- `POST /intercept` - Receive intercepted transactions from iOS apps
- `GET /transactions` - Get all stored transactions
- `DELETE /transactions` - Clear all transactions
- `GET /` - Web interface showing server status

### Example Usage

```bash
# Start server
swift run MyBurpServer

# In your iOS app
MyBurp.configureServer(url: URL(string: "http://localhost:8080")!)

# Query transactions from command line
curl http://localhost:8080/transactions | jq

# Clear transactions
curl -X DELETE http://localhost:8080/transactions
```

See [MyBurpServer README](Sources/MyBurpServer/README.md) for detailed documentation.

## Development Roadmap

- [x] Basic network interception using URLProtocol
- [x] Request/Response data models
- [x] Desktop server communication
- [x] Swift Package Manager support
- [x] NIO-based HTTP server
- [x] REST API for transaction management
- [ ] SwiftUI desktop app UI
- [ ] Request/Response modification interface
- [ ] WebSocket support for real-time updates
- [ ] Filtering and search capabilities
- [ ] Export functionality

## Comparison with Wormholy

| Feature | MyBurp | Wormholy |
|---------|---------|----------|
| Network Interception | ✅ | ✅ |
| In-App UI | ❌ (Desktop App) | ✅ |
| Desktop Integration | ✅ | ❌ |
| Request Modification | 🔄 (Coming) | ❌ |
| Open Source | ✅ | ✅ |
| Size | Lightweight | Full-Featured |

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Inspired by:
- [Wormholy](https://github.com/pmusolino/Wormholy) - iOS network debugging library
- [Burp Suite](https://portswigger.net/burp) - Web application security testing
- [Charles Proxy](https://www.charlesproxy.com/) - HTTP proxy and monitor

## Author

gabystdev

## Notes

This is the iOS interceptor component. The desktop server application (using SwiftUI and NIO) will be developed in subsequent iterations.
