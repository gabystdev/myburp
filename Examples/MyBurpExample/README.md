# MyBurp Example App

This is a simple example iOS app demonstrating how to use the MyBurp network interceptor.

## Features

- Start MyBurp interceptor on app launch
- Make test HTTP requests
- View intercepted network transactions
- Display request method, URL, status code, and timing
- Clear intercepted transactions

## Usage

1. Open this example in Xcode
2. Make sure you have a desktop server running (or disable server in the code)
3. Run the app on a simulator or device
4. Tap "Make Test Request" to make a sample API call to GitHub
5. Tap "Refresh Transactions" to see intercepted requests
6. Tap "Clear Transactions" to reset the list

## Code Highlights

### Starting the Interceptor

```swift
@main
struct MyBurpExampleApp: App {
    init() {
        // Start the network interceptor
        MyBurp.start()
        
        // Configure desktop server (optional)
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

### Viewing Transactions

```swift
// Get all intercepted transactions
let transactions = MyBurp.getTransactions()

for transaction in transactions {
    print("Request: \(transaction.request.method) \(transaction.request.url)")
    if let response = transaction.response {
        print("Response: \(response.statusCode)")
        print("Duration: \(response.duration)s")
    }
}
```

### Clearing Data

```swift
// Clear all intercepted transactions
MyBurp.clearTransactions()
```

## Configuration

To change the desktop server URL, edit `MyBurpExampleApp.swift`:

```swift
// Change localhost to your server's IP address if testing on a device
if let serverURL = URL(string: "http://192.168.1.100:8080") {
    MyBurp.configureServer(url: serverURL, enabled: true)
}
```

## Requirements

- iOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Notes

- All network requests made by the app (including third-party SDKs) will be intercepted
- The interceptor is transparent and doesn't modify the behavior of requests
- Make sure your desktop server is running if you want to see requests forwarded to it
