import SwiftUI
import MyBurpInterceptor

struct TransactionDetailView: View {
    @EnvironmentObject var appState: AppState
    let transaction: NetworkTransaction
    @State private var selectedTab = 0
    @State private var editMode = false
    @State private var editedRequest: RequestModel
    
    init(transaction: NetworkTransaction) {
        self.transaction = transaction
        _editedRequest = State(initialValue: transaction.request.mutableCopy())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with URL and actions
            headerView
            
            Divider()
            
            // Tab view for Request/Response
            TabView(selection: $selectedTab) {
                requestView
                    .tabItem {
                        Label("Request", systemImage: "arrow.up.circle")
                    }
                    .tag(0)
                
                if let response = transaction.response {
                    responseView(response)
                        .tabItem {
                            Label("Response", systemImage: "arrow.down.circle")
                        }
                        .tag(1)
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Method and URL
                Text(transaction.request.method)
                    .font(.title2.bold())
                    .foregroundColor(.blue)
                
                Text(transaction.request.url)
                    .font(.title3)
                    .textSelection(.enabled)
                
                Spacer()
                
                // State badge
                stateBadge
            }
            
            // Action buttons for pending requests
            if transaction.state == .pending || transaction.state == .responsePending {
                HStack {
                    Toggle("Edit Mode", isOn: $editMode)
                        .toggleStyle(.switch)
                    
                    Spacer()
                    
                    Button("Reject") {
                        appState.rejectTransaction(transaction)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button(editMode ? "Approve Modified" : "Approve") {
                        if editMode {
                            var modified = transaction
                            modified.request = editedRequest
                            appState.approveTransaction(modified, modified: true)
                        } else {
                            appState.approveTransaction(transaction)
                        }
                        editMode = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var stateBadge: some View {
        HStack {
            switch transaction.state {
            case .pending:
                Label("Pending", systemImage: "clock.fill")
                    .foregroundColor(.orange)
            case .approved:
                Label("Approved", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .rejected:
                Label("Rejected", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            case .completed:
                Label("Completed", systemImage: "checkmark.circle")
                    .foregroundColor(.blue)
            case .responsePending:
                Label("Response Pending", systemImage: "clock.fill")
                    .foregroundColor(.orange)
            }
            
            if transaction.modified {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.purple)
            }
        }
        .font(.caption)
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var requestView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Headers
                sectionView(title: "Headers") {
                    if editMode {
                        editableHeadersView(headers: $editedRequest.headers)
                    } else {
                        headersView(transaction.request.headers)
                    }
                }
                
                // Body
                if let body = editMode ? editedRequest.body : transaction.request.body {
                    sectionView(title: "Request Body") {
                        bodyView(body, editable: editMode, edited: $editedRequest.body)
                    }
                }
                
                // Metadata
                sectionView(title: "Metadata") {
                    metadataView
                }
            }
            .padding()
        }
    }
    
    private func responseView(_ response: ResponseModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Status
                sectionView(title: "Status") {
                    HStack {
                        Text("\(response.statusCode)")
                            .font(.title.bold())
                            .foregroundColor(statusColor(response.statusCode))
                        
                        Text(httpStatusText(response.statusCode))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Headers
                sectionView(title: "Headers") {
                    headersView(response.headers)
                }
                
                // Body
                if let body = response.body {
                    sectionView(title: "Response Body") {
                        bodyView(body, editable: false, edited: .constant(nil))
                    }
                }
                
                // Timing
                sectionView(title: "Timing") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration: \(String(format: "%.3f seconds", response.duration))")
                        Text("Received: \(formattedDate(response.timestamp))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }
    
    private func sectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
                .padding()
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
        }
    }
    
    private func headersView(_ headers: [String: String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                HStack(alignment: .top) {
                    Text(key + ":")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                        .frame(width: 150, alignment: .trailing)
                    
                    Text(value)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func editableHeadersView(headers: Binding<[String: String]>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(headers.wrappedValue.keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key + ":")
                        .frame(width: 150, alignment: .trailing)
                    
                    TextField("Value", text: Binding(
                        get: { headers.wrappedValue[key] ?? "" },
                        set: { headers.wrappedValue[key] = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                }
            }
            
            Button("Add Header") {
                // TODO: Add header dialog
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func bodyView(_ body: Data, editable: Bool, edited: Binding<Data?>) -> some View {
        VStack(alignment: .leading) {
            if let string = String(data: body, encoding: .utf8) {
                if editable {
                    TextEditor(text: Binding(
                        get: { String(data: edited.wrappedValue ?? body, encoding: .utf8) ?? "" },
                        set: { edited.wrappedValue = $0.data(using: .utf8) }
                    ))
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                } else {
                    Text(string)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
            } else {
                Text("Binary data (\(body.count) bytes)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Transaction ID: \(transaction.id.uuidString)")
                .font(.system(.caption, design: .monospaced))
            Text("Request ID: \(transaction.request.id.uuidString)")
                .font(.system(.caption, design: .monospaced))
            Text("Timestamp: \(formattedDate(transaction.request.timestamp))")
                .font(.system(.caption, design: .monospaced))
        }
        .foregroundColor(.secondary)
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
    
    private func httpStatusText(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 301: return "Moved Permanently"
        case 302: return "Found"
        case 304: return "Not Modified"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        case 502: return "Bad Gateway"
        case 503: return "Service Unavailable"
        default: return "Unknown"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
