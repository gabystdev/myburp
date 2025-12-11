# MyBurp Server

Desktop server application for receiving and displaying intercepted iOS network traffic.

## Overview

MyBurp Server is a NIO-based HTTP server that receives intercepted network transactions from iOS apps using the MyBurpInterceptor library. It provides a REST API for managing intercepted traffic.

## Features

- 🚀 **NIO-based HTTP Server**: High-performance async networking using Swift NIO
- 📥 **Transaction Reception**: Receives intercepted traffic via HTTP POST
- 💾 **In-Memory Storage**: Thread-safe transaction storage
- 🌐 **REST API**: Simple HTTP endpoints for managing data
- 🖥️ **Web Interface**: Basic HTML interface for status monitoring

## Building

```bash
swift build
```

## Running

### Default Port (8080)

```bash
swift run MyBurpServer
```

### Custom Port

```bash
PORT=9090 swift run MyBurpServer
```

Or:

```bash
.build/debug/MyBurpServer
```

## API Endpoints

### POST /intercept

Receive intercepted network transactions from iOS apps.

**Request:**
```json
{
  "id": "uuid",
  "request": {
    "id": "uuid",
    "url": "https://api.example.com/users",
    "method": "GET",
    "headers": { "Content-Type": "application/json" },
    "body": null,
    "timestamp": "2024-01-01T00:00:00Z"
  },
  "response": {
    "id": "uuid",
    "requestId": "uuid",
    "statusCode": 200,
    "headers": { "Content-Type": "application/json" },
    "body": "base64_encoded_data",
    "timestamp": "2024-01-01T00:00:01Z",
    "duration": 0.5
  }
}
```

**Response:**
```json
{
  "status": "received"
}
```

### GET /transactions

Retrieve all intercepted transactions.

**Response:**
```json
[
  {
    "id": "uuid",
    "request": { ... },
    "response": { ... }
  }
]
```

### DELETE /transactions

Clear all stored transactions.

**Response:**
```json
{
  "status": "cleared"
}
```

### GET /

Web interface showing server status and transaction count.

## Architecture

### Components

1. **MyBurpHTTPServer**: Main server class using NIO
2. **HTTPHandler**: Channel handler for processing HTTP requests
3. **TransactionStore**: Thread-safe in-memory storage

### Data Flow

```
iOS App → MyBurpInterceptor → HTTP POST → MyBurpServer → TransactionStore
```

### Thread Safety

- Uses GCD concurrent queue with barriers
- Safe concurrent reads
- Exclusive write access
- No race conditions

## Configuration

Environment variables:
- `PORT`: Server port (default: 8080)

## Testing with iOS App

1. Start the server:
   ```bash
   swift run MyBurpServer
   ```

2. Configure iOS app:
   ```swift
   // Simulator (localhost)
   MyBurp.configureServer(url: URL(string: "http://localhost:8080")!)
   
   // Physical device (use your Mac's IP)
   MyBurp.configureServer(url: URL(string: "http://192.168.1.100:8080")!)
   ```

3. Make network requests in the iOS app

4. View received transactions:
   ```bash
   curl http://localhost:8080/transactions
   ```

## Example Usage

### Start Server
```bash
$ swift run MyBurpServer

╔═══════════════════════════════════════════════════════════════════╗
║                          MyBurp Server                            ║
║                   Network Traffic Interceptor                     ║
╚═══════════════════════════════════════════════════════════════════╝

🚀 MyBurp Server started on [IPv4]0.0.0.0/0.0.0.0:8080
📡 Listening for intercepted traffic...
🌐 Open http://localhost:8080 in your browser
Press Ctrl+C to stop
```

### View Status
```bash
curl http://localhost:8080/
```

### Get Transactions
```bash
curl http://localhost:8080/transactions | jq
```

### Clear Transactions
```bash
curl -X DELETE http://localhost:8080/transactions
```

## Development

### Dependencies

- Swift NIO 2.62.0+
- Swift 5.9+
- macOS 11.0+

### Building for Release

```bash
swift build -c release
```

The binary will be at `.build/release/MyBurpServer`

## Future Enhancements

- [ ] SwiftUI desktop app UI
- [ ] Request/response modification
- [ ] WebSocket support for real-time updates
- [ ] Filtering and search
- [ ] Export functionality (JSON, HAR format)
- [ ] Request replay
- [ ] SSL/TLS support
- [ ] Authentication

## Troubleshooting

### Port Already in Use

If port 8080 is in use, specify a different port:
```bash
PORT=9090 swift run MyBurpServer
```

### Firewall Issues

Make sure your firewall allows incoming connections on the server port.

For macOS:
```bash
# Allow Swift through firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add .build/debug/MyBurpServer
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp .build/debug/MyBurpServer
```

### iOS App Can't Connect

1. Make sure server is running
2. Use correct IP address (not localhost for physical devices)
3. Check that both devices are on same network
4. Verify firewall settings

## Performance

- Handles multiple concurrent connections
- Non-blocking I/O
- Low memory footprint
- Efficient JSON parsing

## Security Notes

⚠️ **Development Use Only**
- No authentication/authorization
- No encryption (HTTP only)
- Stores sensitive data (headers, tokens)
- Should only run on localhost or trusted networks

## License

MIT License - see LICENSE file
