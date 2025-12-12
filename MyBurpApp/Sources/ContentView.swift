import SwiftUI
import MyBurpInterceptor

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            // Sidebar - Transaction List
            TransactionListView()
                .frame(minWidth: 300)
            
            // Detail View
            if let transaction = appState.selectedTransaction {
                TransactionDetailView(transaction: transaction)
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack {
                    Image(systemName: appState.serverRunning ? "circle.fill" : "circle")
                        .foregroundColor(appState.serverRunning ? .green : .red)
                    Text(appState.serverRunning ? "Server Running" : "Server Stopped")
                        .font(.caption)
                    
                    Divider()
                    
                    Text("\(appState.transactions.count) requests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Transaction Selected")
                .font(.title2)
            
            Text("Select a request from the list to view details")
                .foregroundColor(.secondary)
            
            if !appState.serverRunning {
                Divider()
                    .frame(maxWidth: 200)
                
                VStack(spacing: 10) {
                    Text("Server is stopped")
                        .foregroundColor(.orange)
                    
                    Button("Start Server") {
                        appState.startServer()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
