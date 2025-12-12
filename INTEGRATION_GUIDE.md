# End-to-End Integration Guide

Complete guide for testing the full MyBurp system (iOS app + Desktop server).

## Overview

This guide demonstrates the complete workflow:
1. Start the desktop server
2. Configure iOS app to send traffic
3. Make network requests
4. View intercepted traffic on the server

## Prerequisites

- Xcode 15.0+
- Swift 5.9+
- macOS 11.0+
- iOS Simulator or physical iOS device

## Step 1: Build the Project

```bash
cd /path/to/myburp
swift build
```

## Step 2: Start the Desktop Server

Open a terminal and run:

```bash
swift run MyBurpServer
```

You should see:

```
╔═══════════════════════════════════════════════════════════════════╗
║                          MyBurp Server                            ║
║                   Network Traffic Interceptor                     ║
╚═══════════════════════════════════════════════════════════════════╝

🚀 MyBurp Server started on [IPv4]0.0.0.0/0.0.0.0:8080
📡 Listening for intercepted traffic...
🌐 Open http://localhost:8080 in your browser
Press Ctrl+C to stop
```

Keep this terminal open.

## Step 3: Test Server with cURL

In a new terminal, verify the server is running:

```bash
# Check server status
curl http://localhost:8080/

# Check transactions (should be empty)
curl http://localhost:8080/transactions
```

## Step 4: Create iOS Test App

### Option A: Use the Example App

```bash
cd Examples/MyBurpExample
# Open in Xcode and run
```

### Option B: Create New SwiftUI App

1. Create a new SwiftUI app in Xcode
2. Add MyBurp package dependency
3. Update your App struct:

```swift
import SwiftUI
import MyBurpInterceptor

@main
struct TestApp: App {
    init() {
        // Start intercepting
        MyBurp.start()
        
        // Configure server
        // Use localhost for simulator
        let serverURL = URL(string: "http://localhost:8080")!
        
        // Use your Mac's IP for physical device
        // let serverURL = URL(string: "http://192.168.1.100:8080")!
        
        MyBurp.configureServer(url: serverURL, enabled: true)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

4. Add a simple ContentView to make network requests:

```swift
import SwiftUI

struct ContentView: View {
    @State private var result = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Make API Request") {
                makeRequest()
            }
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
            }
            
            Text(result)
                .font(.caption)
        }
        .padding()
    }
    
    func makeRequest() {
        isLoading = true
        result = "Loading..."
        
        let url = URL(string: "https://api.github.com/users/github")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    result = "Error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    result = "Success! Status: \(httpResponse.statusCode)"
                }
            }
        }.resume()
    }
}
```

## Step 5: Run and Test

1. **Run the iOS app** in simulator or device
2. **Tap "Make API Request"** button
3. **Watch the server terminal** - you should see:

```
📥 Received: GET https://api.github.com/users/github
   Status: 200, Duration: 0.45s
```

4. **Query the server** to see stored transactions:

```bash
curl http://localhost:8080/transactions | jq
```

Expected output:

```json
[
  {
    "id": "uuid-here",
    "request": {
      "id": "uuid-here",
      "url": "https://api.github.com/users/github",
      "method": "GET",
      "headers": {
        "Accept": "*/*",
        "User-Agent": "MyApp/1.0"
      },
      "body": null,
      "timestamp": "2024-01-01T12:00:00Z"
    },
    "response": {
      "id": "uuid-here",
      "requestId": "uuid-here",
      "statusCode": 200,
      "headers": {
        "Content-Type": "application/json",
        "Content-Length": "1234"
      },
      "body": "...",
      "timestamp": "2024-01-01T12:00:01Z",
      "duration": 0.45
    }
  }
]
```

## Step 6: Advanced Testing

### Test Multiple Requests

Make several requests from your iOS app and watch them appear on the server.

### Test Different HTTP Methods

```swift
// POST request
var request = URLRequest(url: URL(string: "https://httpbin.org/post")!)
request.httpMethod = "POST"
request.httpBody = Data("{\"test\":\"data\"}".utf8)
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

URLSession.shared.dataTask(with: request) { _, _, _ in
    // Handle response
}.resume()
```

### Clear Transactions

```bash
curl -X DELETE http://localhost:8080/transactions
```

### Check Transaction Count

```bash
curl http://localhost:8080/ | grep "Intercepted Transactions"
```

## Troubleshooting

### iOS App Can't Connect to Server

**Simulator:**
- Use `http://localhost:8080`
- Make sure server is running

**Physical Device:**
1. Get your Mac's IP address:
   ```bash
   # macOS - check which interface (en0, en1, etc.) is active
   ipconfig getifaddr en0
   # or use
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
2. Use that IP: `http://192.168.1.100:8080`
3. Make sure Mac and device are on same WiFi
4. Check firewall settings

### No Traffic Appearing

1. **Verify interceptor is started:**
   ```swift
   MyBurp.start() // Should be called early
   ```

2. **Check server configuration:**
   ```swift
   MyBurp.configureServer(url: serverURL, enabled: true)
   ```

3. **Verify URLSession usage:**
   - MyBurp only intercepts URLSession requests
   - Check that your networking code uses URLSession

4. **Check console logs:**
   - Look for "MyBurp:" messages
   - Check for connection errors

### Port Already in Use

```bash
# Use different port
PORT=9090 swift run MyBurpServer

# Update iOS app
MyBurp.configureServer(url: URL(string: "http://localhost:9090")!)
```

## Performance Testing

### Load Test

Create a script to send multiple requests:

```bash
#!/bin/bash
for i in {1..10}; do
  curl -X POST http://localhost:8080/intercept \
    -H "Content-Type: application/json" \
    -d '{"id":"test-'$i'","request":{"id":"req-'$i'","url":"https://example.com","method":"GET","headers":{},"body":null,"timestamp":"2024-01-01T00:00:00Z"}}'
  echo "Sent request $i"
done
```

### Monitor Memory Usage

```bash
# macOS
ps aux | grep MyBurpServer

# Or use Activity Monitor
```

## Production Checklist

Before using in production (not recommended):

- [ ] Add authentication to server endpoints
- [ ] Enable HTTPS/TLS
- [ ] Implement request filtering (exclude sensitive endpoints)
- [ ] Add rate limiting
- [ ] Implement transaction size limits
- [ ] Add logging and monitoring
- [ ] Set up proper error handling
- [ ] Consider data persistence
- [ ] Add transaction expiration
- [ ] Implement proper shutdown handling

## Next Steps

1. **Explore the API**: Try different endpoints and filters
2. **Build UI**: Create a SwiftUI app for the desktop server
3. **Add Features**: Implement request modification, filtering, export
4. **Contribute**: Submit PRs for new features

## Example Scripts

### View All Transactions (Pretty Print)

```bash
#!/bin/bash
curl -s http://localhost:8080/transactions | jq '.[] | {
  method: .request.method,
  url: .request.url,
  status: .response.statusCode,
  duration: .response.duration
}'
```

### Monitor New Transactions

```bash
#!/bin/bash
# Watch for new transactions every 2 seconds
watch -n 2 'curl -s http://localhost:8080/transactions | jq "length"'
```

### Filter by HTTP Method

```bash
curl -s http://localhost:8080/transactions | jq '.[] | select(.request.method == "POST")'
```

## Resources

- [MyBurp README](../README.md)
- [Server README](../Sources/MyBurpServer/README.md)
- [Quick Start Guide](../QUICK_START.md)
- [Architecture Documentation](../ARCHITECTURE.md)

## Support

Having issues? Check:
1. Server is running
2. iOS app configuration is correct
3. Network connectivity
4. Firewall settings
5. Console logs on both sides
