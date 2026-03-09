import Combine
@preconcurrency import Sparkle
import SwiftUI

@MainActor
final class UpdaterController: ObservableObject {
    let updater: SPUUpdater

    @Published var canCheckForUpdates = false

    init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updater = controller.updater
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func start() {
        do {
            try updater.start()
        } catch {
            print("Failed to start Sparkle updater: \(error)")
        }
    }

    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
