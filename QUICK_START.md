# Quick Start Guide

Get up and running with MyBurp in 5 minutes!

## Step 1: Add the Package

In Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/gabystdev/myburp`
3. Click "Add Package"

Or in `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/gabystdev/myburp.git", from: "1.0.0")
]
```

## Step 2: Start Intercepting

### SwiftUI App

```swift
import SwiftUI
import MyBurpInterceptor

@main
struct YourApp: App {
    init() {
        MyBurp.start()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### UIKit App

```swift
import UIKit
import MyBurpInterceptor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, 
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MyBurp.start()
        return true
    }
}
```

## Step 3: (Optional) Connect to Desktop Server

```swift
if let serverURL = URL(string: "http://192.168.1.100:8080") {
    MyBurp.configureServer(url: serverURL, enabled: true)
}
```

## Step 4: Run Your App

That's it! All HTTP/HTTPS requests are now being intercepted.

## Viewing Intercepted Data

### Programmatically

```swift
let transactions = MyBurp.getTransactions()
for transaction in transactions {
    print("\(transaction.request.method) \(transaction.request.url)")
    if let response = transaction.response {
        print("Status: \(response.statusCode), Duration: \(response.duration)s")
    }
}
```

### Via Desktop Server

When configured, all intercepted data is automatically sent to your desktop server at `POST /intercept` with JSON payload.

## Common Use Cases

### Development/Debugging
```swift
#if DEBUG
MyBurp.start()
#endif
```

### Specific Feature Testing
```swift
// Start before test
MyBurp.start()

// Make requests...

// Check what was sent
let transactions = MyBurp.getTransactions()
XCTAssertEqual(transactions.count, 1)

// Clean up
MyBurp.clearTransactions()
MyBurp.stop()
```

## Configuration Tips

1. **Use localhost** when testing in simulator with desktop server on same machine
2. **Use LAN IP** (e.g., 192.168.1.x) when testing on physical device
3. **Wrap in DEBUG** flag to avoid shipping in production
4. **Clear transactions** periodically to manage memory

## Troubleshooting

### Not seeing requests?
- Check that you're using URLSession (most modern networking uses this)
- Verify MyBurp.start() is called before any requests
- Check that URLs use http:// or https://

### Desktop server not receiving?
- Verify server URL is correct
- Check firewall settings
- Ensure device and server are on same network (for LAN IP)
- Look for "MyBurp:" logs in console

### Memory concerns?
- Call `MyBurp.clearTransactions()` periodically
- Consider implementing a max transactions limit
- Stop intercepting when not needed with `MyBurp.stop()`

## Next Steps

- Check out the [full documentation](README.md)
- Read about the [architecture](ARCHITECTURE.md)
- Run the [example app](Examples/MyBurpExample/README.md)
- Wait for Phase 2: Desktop application with SwiftUI + NIO!

## Support

Found an issue? [Open an issue](https://github.com/gabystdev/myburp/issues)

Want to contribute? [Submit a PR](https://github.com/gabystdev/myburp/pulls)
