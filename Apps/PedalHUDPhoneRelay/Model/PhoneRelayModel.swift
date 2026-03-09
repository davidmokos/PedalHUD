import Foundation
import Observation
import PedalHUDCore

@MainActor
@Observable
final class PhoneRelayModel {
    var currentMetrics = LiveMetrics(
        watts: nil,
        heartRate: 148,
        cadence: nil,
        source: .watchRelay
    )
    var relayStatus = "Waiting for watch heart rate"

    @ObservationIgnored private let relayClient: MacRelayClient
    @ObservationIgnored private let watchReceiver: WatchMetricsReceiver

    init(
        relayClient: MacRelayClient = MacRelayClient(),
        watchReceiver: WatchMetricsReceiver = WatchMetricsReceiver()
    ) {
        self.relayClient = relayClient
        self.watchReceiver = watchReceiver

        self.watchReceiver.onMetrics = { [weak self] message in
            Task { @MainActor in
                self?.ingest(message)
            }
        }

        self.watchReceiver.start()
    }

    func sendPreviewSample() async {
        let message = MetricsBridgeMessage(
            relayIdentifier: "iphone-preview",
            metrics: LiveMetrics(
                watts: 235,
                heartRate: 151,
                cadence: nil,
                source: .phoneRelay
            )
        )

        do {
            try await relayClient.send(message)
            currentMetrics = message.metrics
            relayStatus = "Sent preview payload to the Mac relay"
        } catch {
            relayStatus = error.localizedDescription
        }
    }

    private func ingest(_ message: MetricsBridgeMessage) {
        currentMetrics = message.metrics
        relayStatus = "Received watch update at \(message.sentAt.formatted(date: .omitted, time: .standard))"
    }
}

