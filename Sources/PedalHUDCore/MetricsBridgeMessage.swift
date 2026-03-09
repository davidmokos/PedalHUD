import Foundation

public struct MetricsBridgeMessage: Codable, Equatable, Sendable {
    public var relayIdentifier: String
    public var metrics: LiveMetrics
    public var sentAt: Date
    public var version: Int

    public init(
        relayIdentifier: String,
        metrics: LiveMetrics,
        sentAt: Date = .now,
        version: Int = 1
    ) {
        self.relayIdentifier = relayIdentifier
        self.metrics = metrics
        self.sentAt = sentAt
        self.version = version
    }
}

