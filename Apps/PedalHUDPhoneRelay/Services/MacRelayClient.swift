import Foundation
import PedalHUDCore

struct MacRelayClient {
    var endpoint = URL(string: "http://127.0.0.1:9087/metrics")!

    func send(_ message: MetricsBridgeMessage) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(message)

        _ = try await URLSession.shared.data(for: request)
    }
}

