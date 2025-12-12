import SwiftUI
import MyBurpInterceptor

struct TransactionListView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack {
                TextField("Filter...", text: $appState.filterText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: appState.filterText) { _ in
                        appState.refreshTransactions()
                    }
                
                Toggle("Pending Only", isOn: $appState.showPendingOnly)
                    .toggleStyle(.switch)
                    .onChange(of: appState.showPendingOnly) { _ in
                        appState.refreshTransactions()
                    }
            }
            .padding()
            
            Divider()
            
            // Transaction list
            List(appState.transactions, selection: $appState.selectedTransaction) { transaction in
                TransactionRowView(transaction: transaction)
                    .tag(transaction)
            }
            .listStyle(.sidebar)
        }
    }
}

struct TransactionRowView: View {
    let transaction: NetworkTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Method badge
                Text(transaction.request.method)
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(methodColor.opacity(0.2))
                    .foregroundColor(methodColor)
                    .cornerRadius(4)
                
                // State indicator
                stateIcon
                
                Spacer()
                
                // Status code if available
                if let response = transaction.response {
                    Text("\(response.statusCode)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(statusColor(response.statusCode))
                }
                
                // Modified indicator
                if transaction.modified {
                    Image(systemName: "pencil.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
            }
            
            // URL
            Text(urlPath)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            
            // Timing info
            HStack {
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let response = transaction.response {
                    Text("• \(String(format: "%.0fms", response.duration * 1000))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var methodColor: Color {
        switch transaction.request.method {
        case "GET": return .blue
        case "POST": return .green
        case "PUT": return .orange
        case "DELETE": return .red
        case "PATCH": return .purple
        default: return .gray
        }
    }
    
    private var stateIcon: some View {
        Group {
            switch transaction.state {
            case .pending, .responsePending:
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            case .approved:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .rejected:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .completed:
                EmptyView()
            }
        }
        .font(.caption)
    }
    
    private func statusColor(_ code: Int) -> Color {
        switch code {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500...: return .red
        default: return .gray
        }
    }
    
    private var urlPath: String {
        if let url = URL(string: transaction.request.url) {
            return url.path.isEmpty ? "/" : url.path
        }
        return transaction.request.url
    }
    
    private var timeAgo: String {
        let interval = Date().timeIntervalSince(transaction.request.timestamp)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }
}
