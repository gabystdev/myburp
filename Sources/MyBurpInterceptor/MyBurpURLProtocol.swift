import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Custom URLProtocol that intercepts network requests
public class MyBurpURLProtocol: URLProtocol {
    
    private static let requestIDKey = "MyBurpRequestID"
    private var dataTask: URLSessionDataTask?
    private var receivedData: Data?
    private var startTime: Date?
    private var requestID: UUID?
    
    // MARK: - URLProtocol Override Methods
    
    public override class func canInit(with request: URLRequest) -> Bool {
        // Avoid infinite loops by checking if we've already handled this request
        guard property(forKey: requestIDKey, in: request) == nil else {
            return false
        }
        
        // Only intercept HTTP/HTTPS requests
        guard let scheme = request.url?.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return false
        }
        
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    public override func startLoading() {
        startTime = Date()
        
        // Create a mutable copy of the request and mark it as handled
        guard let newRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorUnknown))
            return
        }
        
        MyBurpURLProtocol.setProperty(true, forKey: MyBurpURLProtocol.requestIDKey, in: newRequest)
        
        // Capture the request
        captureRequest(request)
        
        // Create a session to perform the actual request
        let session = URLSession(configuration: .default)
        dataTask = session.dataTask(with: newRequest as URLRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.client?.urlProtocol(self, didFailWithError: error)
                return
            }
            
            if let response = response {
                self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
                
                // Capture the response
                if let httpResponse = response as? HTTPURLResponse {
                    self.captureResponse(httpResponse, data: data)
                }
            }
            
            if let data = data {
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            self.client?.urlProtocolDidFinishLoading(self)
        }
        
        dataTask?.resume()
    }
    
    public override func stopLoading() {
        dataTask?.cancel()
        dataTask = nil
    }
    
    // MARK: - Capture Methods
    
    private func captureRequest(_ request: URLRequest) {
        let requestModel = RequestModel(
            url: request.url?.absoluteString ?? "",
            method: request.httpMethod ?? "GET",
            headers: request.allHTTPHeaderFields ?? [:],
            body: request.httpBody
        )
        
        // Store the request ID for later matching with response
        requestID = requestModel.id
        NetworkInterceptor.shared.recordRequest(requestModel)
    }
    
    private func captureResponse(_ response: HTTPURLResponse, data: Data?) {
        guard let startTime = startTime else { return }
        guard let requestID = requestID else { return }
        let duration = Date().timeIntervalSince(startTime)
        
        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, element in
            result["\(element.key)"] = "\(element.value)"
        }
        
        let responseModel = ResponseModel(
            requestId: requestID,
            statusCode: response.statusCode,
            headers: headers,
            body: data,
            duration: duration
        )
        
        NetworkInterceptor.shared.recordResponse(responseModel, for: requestID)
    }
}
