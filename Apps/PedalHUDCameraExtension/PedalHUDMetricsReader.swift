import Foundation
import PedalHUDCore

final class PedalHUDMetricsReader: @unchecked Sendable {
    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let lock = NSLock()
    private var cachedMetrics = LiveMetrics.empty
    private var lastRefreshAt = Date.distantPast

    init(appGroupIdentifier: String = PedalHUDIdentifiers.appGroup) {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL.temporaryDirectory
        let fallbackURL = baseDirectory
            .appending(path: "PedalHUD", directoryHint: .isDirectory)
            .appending(path: "live-metrics.json")
        fileURL = (try? FileBackedMetricsStore.appGroupFileURL(appGroupIdentifier: appGroupIdentifier)) ?? fallbackURL
    }

    func latestMetrics() -> LiveMetrics {
        lock.lock()
        defer { lock.unlock() }

        let now = Date.now

        if now.timeIntervalSince(lastRefreshAt) < 0.25 {
            return cachedMetrics
        }

        lastRefreshAt = now
        guard (try? fileURL.checkResourceIsReachable()) == true,
              let data = try? Data(contentsOf: fileURL),
              let metrics = try? decoder.decode(LiveMetrics.self, from: data) else {
            cachedMetrics = .empty
            return cachedMetrics
        }

        cachedMetrics = metrics
        return cachedMetrics
    }
}
