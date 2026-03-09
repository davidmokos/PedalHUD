import Foundation
import PedalHUDCore

struct SharedMetricsWriter {
    private let store: FileBackedMetricsStore

    init(appGroupIdentifier: String = PedalHUDIdentifiers.appGroup) {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL.temporaryDirectory
        let fallbackURL = baseDirectory
            .appending(path: "PedalHUD", directoryHint: .isDirectory)
            .appending(path: "live-metrics.json")
        let fileURL = (try? FileBackedMetricsStore.appGroupFileURL(appGroupIdentifier: appGroupIdentifier)) ?? fallbackURL

        store = FileBackedMetricsStore(fileURL: fileURL)
    }

    func persist(_ metrics: LiveMetrics) async throws {
        try await store.save(metrics)
    }
}
