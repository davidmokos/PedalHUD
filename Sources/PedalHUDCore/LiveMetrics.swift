import Foundation

public struct LiveMetrics: Codable, Equatable, Sendable {
    public var watts: Int?
    public var heartRate: Int?
    public var cadence: Int?
    public var source: MetricSource
    public var receivedAt: Date

    public init(
        watts: Int? = nil,
        heartRate: Int? = nil,
        cadence: Int? = nil,
        source: MetricSource,
        receivedAt: Date = .now
    ) {
        self.watts = watts
        self.heartRate = heartRate
        self.cadence = cadence
        self.source = source
        self.receivedAt = receivedAt
    }

    public static let empty = Self(
        watts: nil,
        heartRate: nil,
        cadence: nil,
        source: .simulator,
        receivedAt: .distantPast
    )

    public func freshness(
        relativeTo now: Date,
        agingAfter: TimeInterval = 1,
        staleAfter: TimeInterval = 3
    ) -> MetricFreshness {
        let age = max(0, now.timeIntervalSince(receivedAt))

        if age < agingAfter {
            return .live
        }

        if age < staleAfter {
            return .aging
        }

        return .stale
    }
}

