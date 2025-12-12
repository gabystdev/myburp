import SwiftUI
import MyBurpInterceptor

@main
struct MyBurpApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // Start the NIO server
        appState.startServer()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("Server") {
                Button(appState.serverRunning ? "Stop Server" : "Start Server") {
                    appState.toggleServer()
                }
                .keyboardShortcut("r", modifiers: [.command])
                
                Divider()
                
                Button("Clear All Transactions") {
                    appState.clearTransactions()
                }
                .keyboardShortcut("k", modifiers: [.command])
            }
            
            CommandMenu("View") {
                Button("Refresh") {
                    appState.refreshTransactions()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}

/// Main application state
class AppState: ObservableObject {
    @Published var transactions: [NetworkTransaction] = []
    @Published var selectedTransaction: NetworkTransaction?
    @Published var serverRunning = false
    @Published var serverPort = 8080
    @Published var filterText = ""
    @Published var showPendingOnly = false
    
    private var refreshTimer: Timer?
    private var server: MyBurpHTTPServer?
    
    init() {
        // Start auto-refresh
        startAutoRefresh()
    }
    
    func startServer() {
        guard !serverRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let server = MyBurpHTTPServer(port: self.serverPort)
                self.server = server
                
                DispatchQueue.main.async {
                    self.serverRunning = true
                }
                
                try server.start()
            } catch {
                print("Failed to start server: \(error)")
                DispatchQueue.main.async {
                    self.serverRunning = false
                }
            }
        }
    }
    
    func stopServer() {
        guard serverRunning else { return }
        
        do {
            try server?.stop()
            serverRunning = false
        } catch {
            print("Failed to stop server: \(error)")
        }
    }
    
    func toggleServer() {
        if serverRunning {
            stopServer()
        } else {
            startServer()
        }
    }
    
    func refreshTransactions() {
        let allTransactions = TransactionStore.shared.getAll()
        
        if showPendingOnly {
            transactions = allTransactions.filter { $0.state == .pending || $0.state == .responsePending }
        } else if filterText.isEmpty {
            transactions = allTransactions
        } else {
            transactions = allTransactions.filter { transaction in
                transaction.request.url.localizedCaseInsensitiveContains(filterText) ||
                transaction.request.method.localizedCaseInsensitiveContains(filterText)
            }
        }
    }
    
    func clearTransactions() {
        TransactionStore.shared.clear()
        refreshTransactions()
        selectedTransaction = nil
    }
    
    func approveTransaction(_ transaction: NetworkTransaction, modified: Bool = false) {
        var updated = transaction
        updated.state = .approved
        if modified {
            updated.modified = true
        }
        TransactionStore.shared.update(updated)
        refreshTransactions()
    }
    
    func rejectTransaction(_ transaction: NetworkTransaction) {
        var updated = transaction
        updated.state = .rejected
        TransactionStore.shared.update(updated)
        refreshTransactions()
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshTransactions()
        }
    }
}
