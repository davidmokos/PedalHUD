import Foundation

public enum MetricSource: String, Codable, CaseIterable, Sendable {
    case directBluetooth
    case phoneRelay
    case watchRelay
    case simulator
}

