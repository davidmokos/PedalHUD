import Foundation
import Testing
@testable import PedalHUDCore

@Test
func fileBackedStoreRoundTripsMetrics() async throws {
    let directory = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    defer {
        try? FileManager.default.removeItem(at: directory)
    }

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    let store = FileBackedMetricsStore(fileURL: directory.appending(path: "metrics.json"))
    let metrics = LiveMetrics(
        watts: 265,
        heartRate: 154,
        cadence: 92,
        source: .phoneRelay,
        receivedAt: Date(timeIntervalSince1970: 42)
    )

    try await store.save(metrics)
    let restored = try await store.load()

    #expect(restored == metrics)
}
