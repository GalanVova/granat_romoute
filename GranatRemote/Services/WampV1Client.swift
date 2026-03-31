import Foundation

/// Minimal WAMP v1 client (CALL / CALLRESULT / CALLERROR).
/// Message type codes: 0 WELCOME, 2 CALL, 3 CALLRESULT, 4 CALLERROR
actor WampV1Client {
    private let uri: URL
    private var webSocketTask: URLSessionWebSocketTask?
    private var pendingCalls: [String: CheckedContinuation<Any?, Error>] = [:]
    private var welcomeContinuation: CheckedContinuation<Void, Error>?

    init(uri: URL) {
        self.uri = uri
    }

    func connect() async throws {
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: uri, protocols: ["wamp"])
        self.webSocketTask = task
        task.resume()

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            self.welcomeContinuation = cont
        }

        startReceiving()
    }

    private func startReceiving() {
        guard let task = webSocketTask else { return }
        Task {
            while true {
                do {
                    let message = try await task.receive()
                    switch message {
                    case .string(let text):
                        await handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            await handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                } catch {
                    await handleError(error)
                    break
                }
            }
        }
    }

    private func handleMessage(_ text: String) async {
        guard
            let data = text.data(using: .utf8),
            let decoded = try? JSONSerialization.jsonObject(with: data) as? [Any],
            let typeInt = decoded.first as? Int
        else { return }

        switch typeInt {
        case 0: // WELCOME
            welcomeContinuation?.resume()
            welcomeContinuation = nil

        case 3: // CALLRESULT: [3, callId, result]
            let callId = decoded.count > 1 ? "\(decoded[1])" : ""
            let result = decoded.count > 2 ? decoded[2] : nil
            if let cont = pendingCalls.removeValue(forKey: callId) {
                cont.resume(returning: result)
            }

        case 4: // CALLERROR: [4, callId, errorUri, errorDesc, ...]
            let callId = decoded.count > 1 ? "\(decoded[1])" : ""
            let errDesc = decoded.count > 3 ? "\(decoded[3])" : "WAMP error"
            if let cont = pendingCalls.removeValue(forKey: callId) {
                cont.resume(throwing: WampError.callError(errDesc))
            }

        default:
            break
        }
    }

    private func handleError(_ error: Error) async {
        welcomeContinuation?.resume(throwing: error)
        welcomeContinuation = nil
        for cont in pendingCalls.values {
            cont.resume(throwing: error)
        }
        pendingCalls.removeAll()
    }

    func call(_ procedure: String, args: [Any]) async throws -> Any? {
        guard let task = webSocketTask else {
            throw WampError.notConnected
        }
        let callId = "\(Date().timeIntervalSince1970 * 1_000_000)"
        let message: [Any] = [2, callId, procedure] + args
        let data = try JSONSerialization.data(withJSONObject: message)
        let text = String(data: data, encoding: .utf8)!

        return try await withCheckedThrowingContinuation { cont in
            pendingCalls[callId] = cont
            task.send(.string(text)) { error in
                if let error {
                    Task { await self.removePending(callId: callId, error: error) }
                }
            }
        }
    }

    private func removePending(callId: String, error: Error) {
        if let cont = pendingCalls.removeValue(forKey: callId) {
            cont.resume(throwing: error)
        }
    }

    func close() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        for cont in pendingCalls.values {
            cont.resume(throwing: WampError.connectionClosed)
        }
        pendingCalls.removeAll()
    }
}

enum WampError: LocalizedError {
    case notConnected
    case connectionClosed
    case callError(String)
    case missingField(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected"
        case .connectionClosed: return "Connection closed"
        case .callError(let msg): return msg
        case .missingField(let f): return "Missing field: \(f)"
        }
    }
}
