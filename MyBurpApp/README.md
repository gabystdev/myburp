# MyBurp Desktop App

Professional SwiftUI macOS application for intercepting and modifying iOS network traffic.

## Features

### ✨ Real-Time Traffic Monitoring
- Live transaction list with auto-refresh
- Filter by URL, method, or status
- View pending requests requiring approval
- Color-coded HTTP methods and status codes
- Transaction timing and metadata

### 🔍 Request/Response Inspector
- Full request and response details
- Headers viewer with copy support
- Body content viewer (text/JSON/binary)
- Timing information and duration
- Transaction state tracking

### ✏️ Request/Response Modification
- **Edit Mode**: Modify requests before they're sent
- Edit headers inline
- Modify request body
- Change HTTP method or URL
- Approve or reject intercepted requests

### 🎯 Intercept Modes
- **Passive**: Just capture, don't block
- **Intercept Requests**: Block and wait for approval
- **Intercept Responses**: Block responses for modification
- **Intercept All**: Full control over all traffic

## Usage

The SwiftUI app code is provided in `MyBurpApp/Sources/`. To use it:

1. Create a new macOS App project in Xcode
2. Add MyBurp package as a dependency
3. Copy the SwiftUI files to your project:
   - MyBurpApp.swift (main app and app state)
   - ContentView.swift (main layout)
   - TransactionListView.swift (sidebar with transaction list)
   - TransactionDetailView.swift (detail pane with modification)

4. Build and run!

## iOS App Configuration

### Basic Setup (Passive Mode)
```swift
import MyBurpInterceptor

MyBurp.start()
MyBurp.configureServer(
    url: URL(string: "http://192.168.1.100:8080")!,
    mode: .passive
)
```

### With Request Interception
```swift
MyBurp.configureServer(
    url: URL(string: "http://192.168.1.100:8080")!,
    mode: .interceptRequests  // Blocks until approved
)
```

### Using Info.plist
Add to your `Info.plist`:
```xml
<key>MyBurpServerURL</key>
<string>http://192.168.1.100:8080</string>
<key>MyBurpInterceptMode</key>
<string>interceptRequests</string>
```

Then:
```swift
MyBurp.startWithConfiguration()
```

## Architecture

```
iOS App (URLProtocol) 
    ↓ Intercepts request
    ↓ Sends to Desktop Server
    ↓
Desktop Server (NIO)
    ↓ Stores in TransactionStore
    ↓ If intercept mode: waits for approval
    ↓
SwiftUI Desktop App
    ↓ Shows request in UI
    ↓ User approves/modifies/rejects
    ↓
Desktop Server
    ↓ Sends response to iOS
    ↓
iOS App
    ↓ Forwards (possibly modified) request
```

## Screenshots

The desktop app provides:
- **Sidebar**: List of all transactions with filtering
- **Detail View**: Full request/response inspector
- **Edit Mode**: Inline modification of headers and body
- **Action Buttons**: Approve/Reject for pending requests

See the main README for complete documentation.
