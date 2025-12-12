# MyBurp - Professional iOS Network Traffic Interceptor

A powerful iOS network interceptor with desktop modification capabilities, similar to Burp Suite and Charles Proxy. Intercept, inspect, and modify HTTP/HTTPS requests in real-time.

## Features

### 🔥 Core Capabilities
- 🔍 **Network Interception**: Automatically intercept all HTTP/HTTPS requests using URLProtocol
- ✏️ **Request/Response Modification**: Edit requests before they're sent, modify responses
- 🚦 **Multiple Intercept Modes**: Passive monitoring or active interception with approval
- 📡 **Desktop Server**: NIO-based HTTP server with full REST API
- 🖥️ **Professional SwiftUI App**: Beautiful macOS app for managing intercepted traffic
- 📦 **Easy Integration**: Simple API with xcconfig/Info.plist configuration support

### 🎯 Intercept Modes
- **Passive**: Capture traffic without blocking (like Wormholy)
- **Intercept Requests**: Block requests and wait for approval/modification (like Burp)
- **Intercept Responses**: Block responses for modification
- **Intercept All**: Full control over both requests and responses

## Architecture

MyBurp consists of three main components:

1. **iOS Interceptor Library** (`MyBurpInterceptor`): URLProtocol-based interceptor with blocking/modification support
2. **Desktop Server** (`MyBurpServer`): NIO-based HTTP server handling approval/rejection
3. **SwiftUI Desktop App** (`MyBurpApp`): Professional UI for inspecting and modifying traffic

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

## Quick Start

### iOS App - Passive Mode (Just Capture)

```swift
import MyBurpInterceptor

@main
struct MyApp: App {
    init() {
        MyBurp.start()
        MyBurp.configureServer(
            url: URL(string: "http://192.168.1.100:8080")!,
            mode: .passive
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### iOS App - Intercept Mode (With Modification)

```swift
import MyBurpInterceptor

@main
struct MyApp: App {
    init() {
        MyBurp.start()
        MyBurp.configureServer(
            url: URL(string: "http://192.168.1.100:8080")!,
            mode: .interceptRequests  // Blocks until approved!
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### iOS App - Easy Configuration via Info.plist

Add to your `Info.plist`:
```xml
<key>MyBurpServerURL</key>
<string>http://192.168.1.100:8080</string>
<key>MyBurpInterceptMode</key>
<string>interceptRequests</string>
<key>MyBurpTimeout</key>
<real>30.0</real>
```

Then just:
```swift
MyBurp.startWithConfiguration()
```

### Desktop Server

```bash
# Start the server
swift run MyBurpServer

# Server listens on port 8080
# iOS app connects and sends traffic
```

### Desktop SwiftUI App

The SwiftUI app provides a professional UI for:
- Viewing all intercepted traffic in real-time
- Inspecting request/response details
- **Modifying requests inline** (headers, body, method, URL)
- **Approving or rejecting** intercepted requests
- Filtering and searching transactions

See `MyBurpApp/README.md` for setup instructions.

## How It Works

### Passive Mode (Default)
1. iOS app makes HTTP request
2. URLProtocol intercepts it
3. Request is captured and sent to server
4. Original request proceeds normally
5. Response is captured when it returns

### Intercept Mode (Burp-like)
1. iOS app makes HTTP request
2. URLProtocol intercepts it
3. Request is sent to server and **iOS app blocks**
4. Desktop app shows request in UI
5. User can modify headers/body/URL
6. User approves or rejects
7. Server sends response back to iOS
8. iOS proceeds with (possibly modified) request

## Configuration Options

### Intercept Modes
```swift
.passive              // Just capture, don't block
.interceptRequests    // Block requests for approval
.interceptResponses   // Block responses for modification  
.interceptAll         // Block both requests and responses
```

### Full Configuration
```swift
var config = MyBurpConfiguration()
config.serverURL = URL(string: "http://192.168.1.100:8080")
config.interceptMode = .interceptRequests
config.timeout = 30.0  // Timeout for pending requests
MyBurp.configure(config)
```

### xcconfig Configuration
Create `MyBurp.xcconfig`:
```
MYBURP_SERVER_URL = http://192.168.1.100:8080
MYBURP_INTERCEPT_MODE = interceptRequests
MYBURP_TIMEOUT = 30.0
```

Add to `Info.plist`:
```xml
<key>MyBurpServerURL</key>
<string>$(MYBURP_SERVER_URL)</string>
<key>MyBurpInterceptMode</key>
<string>$(MYBURP_INTERCEPT_MODE)</string>
<key>MyBurpTimeout</key>
<real>$(MYBURP_TIMEOUT)</real>
```

## Desktop Server API

The NIO-based server provides these endpoints:

- `POST /intercept` - Receive completed transactions (passive mode)
- `POST /intercept-request` - Receive blocking requests (intercept mode)
- `POST /approve/:id` - Approve a pending request (optionally with modifications)
- `POST /reject/:id` - Reject a pending request
- `GET /transactions` - Get all transactions
- `GET /pending` - Get only pending transactions
- `DELETE /transactions` - Clear all transactions

### Example: Approving a Modified Request

```bash
curl -X POST http://localhost:8080/approve/TRANSACTION_ID \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://api.example.com/modified",
    "method": "POST",
    "headers": {"X-Custom": "Modified"},
    "body": null
  }'
```

## Desktop SwiftUI App

Professional macOS app with:

- **Real-time transaction list** with auto-refresh
- **Full request/response inspector** with syntax highlighting
- **Inline editor** for modifying requests
- **Approve/Reject buttons** for pending requests
- **Filtering and search**
- **Keyboard shortcuts** (⌘R, ⌘K, etc.)

To use:
1. Create new macOS App in Xcode
2. Add MyBurp package dependency
3. Copy SwiftUI files from `MyBurpApp/Sources/`
4. Build and run

## Access Intercepted Traffic Programmatically

You can access intercepted network transactions in your iOS app:

```swift
// Get all intercepted transactions
let transactions = MyBurp.getTransactions()

for transaction in transactions {
    print("Request: \(transaction.request.method) \(transaction.request.url)")
    print("State: \(transaction.state)")
    if transaction.modified {
        print("Request was modified!")
    }
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
