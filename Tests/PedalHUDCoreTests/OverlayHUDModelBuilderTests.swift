import Foundation
import Testing
@testable import PedalHUDCore

@Test
func buildCreatesLiveHUDFromFreshMetrics() {
    let builder = OverlayHUDModelBuilder()
    let now = Date(timeIntervalSince1970: 1_741_000_000)
    let metrics = LiveMetrics(
        watts: 248,
        heartRate: 156,
        cadence: 91,
        source: .directBluetooth,
        receivedAt: now
    )

    let hud = builder.build(metrics: metrics, now: now)

    #expect(hud.items.count == 2)
    #expect(hud.items[0].value == "248 W")
    #expect(hud.items[1].value == "156 bpm")
    #expect(hud.freshness == .live)
}

@Test
func buildMarksOldMetricsAsStale() {
    let builder = OverlayHUDModelBuilder()
    let receivedAt = Date(timeIntervalSince1970: 1_741_000_000)
    let metrics = LiveMetrics(
        watts: 210,
        heartRate: 149,
        cadence: 88,
        source: .phoneRelay,
        receivedAt: receivedAt
    )

    let hud = builder.build(
        metrics: metrics,
        configuration: .init(staleAfter: 2),
        now: receivedAt.addingTimeInterval(4)
    )

    #expect(hud.freshness == .stale)
}

