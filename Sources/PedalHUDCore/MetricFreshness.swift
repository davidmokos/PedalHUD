import Foundation

public enum MetricFreshness: String, Codable, CaseIterable, Sendable {
    case live
    case aging
    case stale
}

