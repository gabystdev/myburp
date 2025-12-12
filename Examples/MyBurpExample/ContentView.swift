import SwiftUI
import MyBurpInterceptor

struct ContentView: View {
    @State private var transactions: [NetworkTransaction] = []
    @State private var isLoading = false
    @State private var statusMessage = "Ready"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Status
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: makeTestRequest) {
                        HStack {
                            Image(systemName: "network")
                            Text("Make Test Request")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)
                    
                    Button(action: refreshTransactions) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Transactions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: clearTransactions) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Transactions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Transactions List
                List {
                    ForEach(transactions) { transaction in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(transaction.request.method)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                if let response = transaction.response {
                                    Text("\(response.statusCode)")
                                        .font(.subheadline)
                                        .foregroundColor(statusColor(for: response.statusCode))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(statusColor(for: response.statusCode).opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            
                            Text(transaction.request.url)
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            HStack {
                                Text(formatDate(transaction.request.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                if let response = transaction.response {
                                    Text("• \(String(format: "%.2fs", response.duration))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                
                Text("Intercepted \(transactions.count) request(s)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationTitle("MyBurp Example")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshTransactions()
        }
    }
    
    // MARK: - Actions
    
    private func makeTestRequest() {
        isLoading = true
        statusMessage = "Making request..."
        
        // Make a test HTTP request
        guard let url = URL(string: "https://api.github.com/users/github") else {
            statusMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    statusMessage = "Error: \(error.localizedDescription)"
                } else if let httpResponse = response as? HTTPURLResponse {
                    statusMessage = "Request completed with status \(httpResponse.statusCode)"
                    
                    // Wait a bit for the interceptor to process, then refresh
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        refreshTransactions()
                    }
                }
            }
        }.resume()
    }
    
    private func refreshTransactions() {
        transactions = MyBurp.getTransactions()
        statusMessage = "Showing \(transactions.count) transaction(s)"
    }
    
    private func clearTransactions() {
        MyBurp.clearTransactions()
        transactions = []
        statusMessage = "Transactions cleared"
    }
    
    // MARK: - Helpers
    
    private func statusColor(for statusCode: Int) -> Color {
        switch statusCode {
        case 200..<300:
            return .green
        case 300..<400:
            return .orange
        case 400..<500:
            return .red
        case 500..<600:
            return .purple
        default:
            return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
