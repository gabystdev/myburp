import SwiftUI
import MyBurpInterceptor

@main
struct MyBurpExampleApp: App {
    
    init() {
        // Start the network interceptor
        MyBurp.start()
        
        // Configure desktop server (change to your server's IP/port)
        if let serverURL = URL(string: "http://localhost:8080") {
            MyBurp.configureServer(url: serverURL, enabled: true)
        }
        
        print("MyBurp network interceptor started!")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
