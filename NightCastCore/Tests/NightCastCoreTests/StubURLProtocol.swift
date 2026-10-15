import Foundation

/// Serves canned HTTP responses. Tests using it run serialized via the
/// `.serialized` trait on the parent suite to avoid racing on shared state.
final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var requests: [URLRequest] = []
    /// Per-URL bodies (absolute string → (status, body)); falls back to `status`/`body`.
    nonisolated(unsafe) static var routes: [String: (Int, Data)] = [:]
    static let lock = NSLock()

    static func respond(status: Int, body: Data) {
        lock.withLock {
            self.status = status
            self.body = body
            self.routes = [:]
        }
    }

    static func route(_ routes: [String: (Int, Data)]) {
        lock.withLock { self.routes = routes }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (status, body) = Self.lock.withLock {
            Self.requests.append(request)
            return Self.routes[request.url!.absoluteString] ?? (Self.status, Self.body)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

extension URLSession {
    static var stubbed: URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }
}
