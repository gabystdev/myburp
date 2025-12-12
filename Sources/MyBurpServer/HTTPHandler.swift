import Foundation
import MyBurpInterceptor
import NIOCore
import NIOHTTP1

/// HTTP request handler that processes incoming requests
final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    
    private var requestBody: ByteBuffer?
    private var requestHead: HTTPRequestHead?
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        switch reqPart {
        case .head(let head):
            self.requestHead = head
            self.requestBody = nil
            
        case .body(var buffer):
            if self.requestBody == nil {
                self.requestBody = buffer
            } else {
                self.requestBody?.writeBuffer(&buffer)
            }
            
        case .end:
            guard let head = self.requestHead else {
                sendError(context: context, message: "Invalid request")
                return
            }
            
            handleRequest(context: context, head: head, body: self.requestBody)
            self.requestHead = nil
            self.requestBody = nil
        }
    }
    
    private func handleRequest(context: ChannelHandlerContext, head: HTTPRequestHead, body: ByteBuffer?) {
        // Route the request
        switch (head.method, head.uri) {
        case (.POST, "/intercept"):
            handleInterceptEndpoint(context: context, head: head, body: body)
            
        case (.POST, "/intercept-request"):
            handleInterceptRequestEndpoint(context: context, head: head, body: body)
            
        case (.POST, let uri) where uri.starts(with: "/approve/"):
            handleApproveRequest(context: context, head: head, uri: uri, body: body)
            
        case (.POST, let uri) where uri.starts(with: "/reject/"):
            handleRejectRequest(context: context, head: head, uri: uri)
            
        case (.GET, "/transactions"):
            handleGetTransactions(context: context, head: head)
            
        case (.GET, "/pending"):
            handleGetPendingTransactions(context: context, head: head)
            
        case (.DELETE, "/transactions"):
            handleClearTransactions(context: context, head: head)
            
        case (.GET, "/"):
            handleRoot(context: context, head: head)
            
        default:
            sendNotFound(context: context)
        }
    }
    
    private func handleInterceptEndpoint(context: ChannelHandlerContext, head: HTTPRequestHead, body: ByteBuffer?) {
        guard var body = body else {
            sendError(context: context, message: "No body provided")
            return
        }
        
        guard let bytes = body.readBytes(length: body.readableBytes) else {
            sendError(context: context, message: "Failed to read body data")
            return
        }
        
        let data = Data(bytes)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let transaction = try decoder.decode(NetworkTransaction.self, from: data)
            
            // Store the transaction
            TransactionStore.shared.add(transaction)
            
            print("📥 Received: \(transaction.request.method) \(transaction.request.url)")
            if let response = transaction.response {
                print("   Status: \(response.statusCode), Duration: \(String(format: "%.2fs", response.duration))")
            }
            
            sendJSON(context: context, statusCode: .ok, data: ["status": "received"])
        } catch {
            sendError(context: context, message: "Failed to decode transaction: \(error.localizedDescription)")
        }
    }
    
    private func handleInterceptRequestEndpoint(context: ChannelHandlerContext, head: HTTPRequestHead, body: ByteBuffer?) {
        guard var body = body else {
            sendError(context: context, message: "No body provided")
            return
        }
        
        guard let bytes = body.readBytes(length: body.readableBytes) else {
            sendError(context: context, message: "Failed to read body data")
            return
        }
        
        let data = Data(bytes)
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let interceptRequest = try decoder.decode(InterceptRequest.self, from: data)
            
            print("🔒 Intercepted Request: \(interceptRequest.request.method) \(interceptRequest.request.url)")
            print("   Transaction ID: \(interceptRequest.transactionId)")
            print("   Waiting for user action...")
            
            // Store as pending
            let transaction = NetworkTransaction(
                id: interceptRequest.transactionId,
                request: interceptRequest.request,
                response: nil,
                state: .pending,
                modified: false
            )
            TransactionStore.shared.add(transaction)
            
            // TODO: In production, desktop UI will make the approval decision
            // For now, we auto-approve to demonstrate the flow
            // The SwiftUI desktop app provides the UI for manual approval
            
            // Send response to approve forwarding
            let encoder = JSONEncoder()
            let response = InterceptResponse(
                transactionId: interceptRequest.transactionId,
                action: .forward,  // Auto-approve: forward original request
                modifiedRequest: nil,
                modifiedResponse: nil
            )
            let responseData = try encoder.encode(response)
            sendJSON(context: context, statusCode: .ok, rawData: responseData)
            
        } catch {
            sendError(context: context, message: "Failed to decode intercept request: \(error.localizedDescription)")
        }
    }
    
    private func handleApproveRequest(context: ChannelHandlerContext, head: HTTPRequestHead, uri: String, body: ByteBuffer?) {
        // Extract transaction ID from URI
        let components = uri.split(separator: "/")
        guard components.count >= 2,
              let transactionId = UUID(uuidString: String(components[1])) else {
            sendError(context: context, message: "Invalid transaction ID")
            return
        }
        
        // Check if there's a modified request in the body
        var modifiedRequest: RequestModel? = nil
        if let body = body, var bodyBuffer = body as ByteBuffer? {
            if let bytes = bodyBuffer.readBytes(length: bodyBuffer.readableBytes) {
                let data = Data(bytes)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                modifiedRequest = try? decoder.decode(RequestModel.self, from: data)
            }
        }
        
        // Update transaction state
        if let transaction = TransactionStore.shared.getTransaction(id: transactionId) {
            var updatedTransaction = transaction
            updatedTransaction.state = .approved
            if let modified = modifiedRequest {
                updatedTransaction.request = modified
                updatedTransaction.modified = true
            }
            TransactionStore.shared.update(updatedTransaction)
            
            print("✅ Approved: \(updatedTransaction.request.method) \(updatedTransaction.request.url)")
            if updatedTransaction.modified {
                print("   (Modified)")
            }
            
            sendJSON(context: context, statusCode: .ok, data: ["status": "approved"])
        } else {
            sendError(context: context, message: "Transaction not found")
        }
    }
    
    private func handleRejectRequest(context: ChannelHandlerContext, head: HTTPRequestHead, uri: String) {
        // Extract transaction ID from URI
        let components = uri.split(separator: "/")
        guard components.count >= 2,
              let transactionId = UUID(uuidString: String(components[1])) else {
            sendError(context: context, message: "Invalid transaction ID")
            return
        }
        
        // Update transaction state
        if let transaction = TransactionStore.shared.getTransaction(id: transactionId) {
            var updatedTransaction = transaction
            updatedTransaction.state = .rejected
            TransactionStore.shared.update(updatedTransaction)
            
            print("🚫 Rejected: \(updatedTransaction.request.method) \(updatedTransaction.request.url)")
            
            sendJSON(context: context, statusCode: .ok, data: ["status": "rejected"])
        } else {
            sendError(context: context, message: "Transaction not found")
        }
    }
    
    private func handleGetPendingTransactions(context: ChannelHandlerContext, head: HTTPRequestHead) {
        let pending = TransactionStore.shared.getPending()
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(pending)
            
            sendJSON(context: context, statusCode: .ok, rawData: data)
        } catch {
            sendError(context: context, message: "Failed to encode pending transactions: \(error.localizedDescription)")
        }
    }
    
    private func handleGetTransactions(context: ChannelHandlerContext, head: HTTPRequestHead) {
        let transactions = TransactionStore.shared.getAll()
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(transactions)
            
            sendJSON(context: context, statusCode: .ok, rawData: data)
        } catch {
            sendError(context: context, message: "Failed to encode transactions: \(error.localizedDescription)")
        }
    }
    
    private func handleClearTransactions(context: ChannelHandlerContext, head: HTTPRequestHead) {
        TransactionStore.shared.clear()
        sendJSON(context: context, statusCode: .ok, data: ["status": "cleared"])
    }
    
    private func handleRoot(context: ChannelHandlerContext, head: HTTPRequestHead) {
        let transactionCount = TransactionStore.shared.count()
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>MyBurp Server</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; margin: 40px; }
                h1 { color: #333; }
                .info { background: #f0f0f0; padding: 20px; border-radius: 8px; }
                code { background: #e0e0e0; padding: 2px 6px; border-radius: 3px; }
            </style>
        </head>
        <body>
            <h1>MyBurp Server Running 🚀</h1>
            <div class="info">
                <p><strong>Status:</strong> Active</p>
                <p><strong>Intercepted Transactions:</strong> \(transactionCount)</p>
                <h3>API Endpoints:</h3>
                <ul>
                    <li><code>POST /intercept</code> - Receive intercepted transactions</li>
                    <li><code>GET /transactions</code> - Get all transactions</li>
                    <li><code>DELETE /transactions</code> - Clear all transactions</li>
                </ul>
            </div>
        </body>
        </html>
        """
        
        sendHTML(context: context, html: html)
    }
    
    // MARK: - Response Helpers
    
    private func sendJSON(context: ChannelHandlerContext, statusCode: HTTPResponseStatus, data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data) else {
            sendError(context: context, message: "Failed to serialize JSON")
            return
        }
        sendJSON(context: context, statusCode: statusCode, rawData: jsonData)
    }
    
    private func sendJSON(context: ChannelHandlerContext, statusCode: HTTPResponseStatus, rawData: Data) {
        var buffer = context.channel.allocator.buffer(capacity: rawData.count)
        buffer.writeBytes(rawData)
        
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "Content-Length", value: "\(rawData.count)")
        headers.add(name: "Access-Control-Allow-Origin", value: "*")
        
        let responseHead = HTTPResponseHead(version: .http1_1, status: statusCode, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    private func sendHTML(context: ChannelHandlerContext, html: String) {
        var buffer = context.channel.allocator.buffer(capacity: html.utf8.count)
        buffer.writeString(html)
        
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html; charset=utf-8")
        headers.add(name: "Content-Length", value: "\(html.utf8.count)")
        
        let responseHead = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }
    
    private func sendError(context: ChannelHandlerContext, message: String) {
        sendJSON(context: context, statusCode: .badRequest, data: ["error": message])
    }
    
    private func sendNotFound(context: ChannelHandlerContext) {
        sendJSON(context: context, statusCode: .notFound, data: ["error": "Not found"])
    }
}
