# MyBurp Architecture

## Overview

MyBurp is designed as a two-part system for intercepting and modifying iOS network traffic:

1. **iOS Library** (Current): Intercepts network requests and forwards them to a desktop app
2. **Desktop Application** (Future): Receives, displays, and allows modification of requests/responses

## iOS Library Architecture

### Core Components

#### 1. MyBurpURLProtocol
- **Purpose**: Custom URLProtocol that intercepts all HTTP/HTTPS requests
- **Mechanism**: Registers with iOS URL loading system using `URLProtocol.registerClass()`
- **Functionality**:
  - Intercepts requests before they're sent
  - Allows original request to proceed
  - Captures both request and response data
  - Forwards data to NetworkInterceptor

#### 2. NetworkInterceptor
- **Purpose**: Manages intercepted traffic and server communication
- **Pattern**: Singleton for app-wide access
- **Responsibilities**:
  - Store intercepted transactions
  - Match requests with responses
  - Send data to desktop server
  - Provide API for accessing intercepted data
- **Thread Safety**: Uses concurrent dispatch queue with barriers for safe access

#### 3. Data Models

**RequestModel**
```swift
struct RequestModel {
    id: UUID
    url: String
    method: String
    headers: [String: String]
    body: Data?
    timestamp: Date
}
```

**ResponseModel**
```swift
struct ResponseModel {
    id: UUID
    requestId: UUID
    statusCode: Int
    headers: [String: String]
    body: Data?
    timestamp: Date
    duration: TimeInterval
}
```

**NetworkTransaction**
```swift
struct NetworkTransaction {
    id: UUID
    request: RequestModel
    response: ResponseModel?
}
```

#### 4. MyBurp (Public API)
- **Purpose**: Simple, clean public API for library users
- **Methods**:
  - `start()`: Begin intercepting
  - `stop()`: Stop intercepting
  - `configureServer()`: Set desktop server URL
  - `getTransactions()`: Access intercepted data
  - `clearTransactions()`: Reset stored data

### Data Flow

```
iOS App → URLSession → MyBurpURLProtocol → NetworkInterceptor → Desktop Server
                            ↓
                      Original Request
                            ↓
                      Remote Server
                            ↓
                      Response Data
                            ↓
                      MyBurpURLProtocol → NetworkInterceptor → Desktop Server
                            ↓
                      iOS App
```

### URLProtocol Interception

URLProtocol is an abstract class that can intercept URL loading:

1. **Registration**: `URLProtocol.registerClass()` registers custom protocol
2. **Evaluation**: System calls `canInit(with:)` for each request
3. **Handling**: If `true`, system calls `startLoading()` to handle request
4. **Execution**: Custom protocol makes actual request and captures data
5. **Forwarding**: Data is sent back to original caller via `client` callbacks

### Thread Safety

- Uses GCD with concurrent queue and barriers
- Read operations execute concurrently
- Write operations use barriers for exclusive access
- Prevents race conditions when multiple requests complete simultaneously

## Desktop Server Communication

### Protocol

Intercepted data is sent via HTTP POST to `/intercept` endpoint:

```http
POST /intercept HTTP/1.1
Host: localhost:8080
Content-Type: application/json

{
  "id": "transaction-uuid",
  "request": { ... },
  "response": { ... }
}
```

### Design Decisions

1. **HTTP over WebSocket**: Simpler initial implementation
   - Future: Could add WebSocket for bidirectional communication
   - Would enable request/response modification

2. **JSON Encoding**: Standard, readable format
   - Binary data encoded as base64
   - ISO 8601 timestamps

3. **Fire-and-forget**: iOS app doesn't wait for server response
   - Prevents blocking app's network requests
   - Errors logged but don't affect app functionality

## Comparison with Wormholy

### Similarities
- Both use URLProtocol for interception
- Both capture request/response data
- Both provide programmatic access to intercepted data

### Differences

| Aspect | MyBurp | Wormholy |
|--------|---------|----------|
| UI | Desktop app (external) | In-app overlay |
| Modification | Planned feature | Not supported |
| Storage | In-memory | Persistent storage |
| Size | Minimal (single purpose) | Full-featured |
| Use Case | Development/debugging | Development/QA |

## Future Enhancements

### Desktop Application (Phase 2)
- **Technology**: SwiftUI + Swift NIO
- **Features**:
  - Real-time transaction display
  - Request/response inspection
  - Modification interface
  - Filtering and search
  - Export functionality

### WebSocket Communication
- Bidirectional real-time updates
- Request modification before sending
- Response modification before receiving
- Better performance than polling

### Advanced Features
- SSL pinning bypass options
- Custom request replay
- Traffic filtering rules
- Response mocking
- Performance metrics

## Design Principles

1. **Minimal Impact**: Library should not affect app performance
2. **Transparent**: Original requests proceed normally
3. **Simple API**: Easy integration, minimal configuration
4. **Type Safe**: Leverage Swift's type system
5. **Thread Safe**: Handle concurrent requests safely
6. **Extensible**: Design for future enhancement

## Implementation Notes

### Why URLProtocol?

URLProtocol is the standard way to intercept URLSession requests:
- Built into iOS/macOS
- Works with all URLSession-based networking
- No private APIs or swizzling needed
- Supported by Apple

### Limitations

1. **URLSession Only**: Doesn't intercept lower-level networking (CFNetwork directly)
2. **Third-party SDKs**: Only works if they use URLSession
3. **System Requests**: Can't intercept system-level requests
4. **Certificate Pinning**: Might not work with apps that implement strict pinning

### Performance Considerations

- Minimal overhead: Just data copying
- Concurrent queue allows parallel processing
- Server communication is async and non-blocking
- Memory limited by transaction count (can be cleared)

## Testing Strategy

1. **Unit Tests**: Test data models and interceptor logic
2. **Integration Tests**: Test actual request interception
3. **Example App**: Real-world usage demonstration
4. **Performance Tests**: Measure overhead and memory usage

## Security Considerations

- **Data Privacy**: Intercepted data includes headers (may contain tokens)
- **Local Network Only**: Server should only listen on localhost/LAN
- **Development Use**: Not intended for production builds
- **Compilation Flags**: Recommend `#if DEBUG` guards

## Dependencies

- **Foundation**: Core Swift framework
- **FoundationNetworking**: Network types (Linux compatibility)
- **No external dependencies**: Keeps library lightweight

## Platform Support

- **iOS 14.0+**: URLProtocol and required APIs
- **macOS 11.0+**: For desktop server (future)
- **Swift 5.9+**: Modern Swift features
- **Linux**: Limited (compilation only, not full functionality)
