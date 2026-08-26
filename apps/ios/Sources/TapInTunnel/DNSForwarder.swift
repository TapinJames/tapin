import Foundation
import Network
import os

/// Forwards DNS queries to upstream resolvers over UDP.
class DNSForwarder {
    private let logger = Logger(subsystem: "com.tapinschools.tapin.tunnel", category: "DNSForwarder")
    private let resolvers: [String]
    private let queue = DispatchQueue(label: "com.tapinschools.tapin.dnsforwarder")

    /// Pending queries waiting for responses
    private var pendingQueries: [UInt16: (Data, (Data?) -> Void)] = [:]

    init(resolvers: [String]) {
        self.resolvers = resolvers
    }

    /// Forward a DNS query to upstream resolvers.
    func forward(query: Data, completion: @escaping (Data?) -> Void) {
        guard query.count >= 2 else {
            completion(nil)
            return
        }

        // Get transaction ID
        let transactionId = UInt16(query[0]) << 8 | UInt16(query[1])

        // Store pending query
        queue.async { [weak self] in
            self?.pendingQueries[transactionId] = (query, completion)
        }

        // Try primary resolver first
        sendQuery(query, to: resolvers[0], port: 53) { [weak self] response in
            if let response = response {
                self?.handleResponse(transactionId: transactionId, response: response)
            } else if let self = self, self.resolvers.count > 1 {
                // Fallback to secondary resolver
                self.sendQuery(query, to: self.resolvers[1], port: 53) { response in
                    self.handleResponse(transactionId: transactionId, response: response)
                }
            } else {
                self?.handleResponse(transactionId: transactionId, response: nil)
            }
        }
    }

    private func sendQuery(_ query: Data, to host: String, port: UInt16, completion: @escaping (Data?) -> Void) {
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        let connection = NWConnection(to: endpoint, using: .udp)

        var completed = false
        let completeOnce: (Data?) -> Void = { response in
            guard !completed else { return }
            completed = true
            completion(response)
        }

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                // Send query
                connection.send(content: query, completion: .contentProcessed { error in
                    if error != nil {
                        completeOnce(nil)
                        connection.cancel()
                    }
                })

                // Receive response
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { data, _, _, error in
                    completeOnce(data)
                    connection.cancel()
                }
            case .failed, .cancelled:
                completeOnce(nil)
            default:
                break
            }
        }

        connection.start(queue: queue)

        // Timeout after 2 seconds
        queue.asyncAfter(deadline: .now() + 2.0) {
            completeOnce(nil)
            connection.cancel()
        }
    }

    private func handleResponse(transactionId: UInt16, response: Data?) {
        queue.async { [weak self] in
            guard let (_, completion) = self?.pendingQueries.removeValue(forKey: transactionId) else {
                return
            }
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
}
