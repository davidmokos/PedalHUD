import Foundation

public actor FileBackedMetricsStore {
    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> LiveMetrics? {
        guard (try? fileURL.checkResourceIsReachable()) == true else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(LiveMetrics.self, from: data)
    }

    public func save(_ metrics: LiveMetrics) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let data = try encoder.encode(metrics)
        try data.write(to: fileURL, options: [.atomic])
    }

    public static func appGroupFileURL(
        appGroupIdentifier: String,
        fileName: String = "live-metrics.json"
    ) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            throw NSError(
                domain: "PedalHUDCore.FileBackedMetricsStore",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Unable to resolve the App Group container for \(appGroupIdentifier)."
                ]
            )
        }

        return containerURL.appending(path: fileName)
    }
}

