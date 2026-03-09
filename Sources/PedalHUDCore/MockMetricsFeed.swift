import Foundation

public struct MockMetricsFeed: Sendable {
    public init() {}

    public func stream(interval: Duration = .seconds(1)) -> AsyncStream<LiveMetrics> {
        AsyncStream { continuation in
            let task = Task {
                var watts = 180
                var heartRate = 132
                var direction = 1

                while !Task.isCancelled {
                    continuation.yield(
                        LiveMetrics(
                            watts: watts,
                            heartRate: heartRate,
                            cadence: 90,
                            source: .simulator
                        )
                    )

                    watts += 10 * direction
                    heartRate += 1 * direction

                    if watts >= 320 {
                        direction = -1
                    } else if watts <= 140 {
                        direction = 1
                    }

                    do {
                        try await Task.sleep(for: interval)
                    } catch {
                        break
                    }
                }

                continuation.finish()
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
}

