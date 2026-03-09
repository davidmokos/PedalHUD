import SwiftUI

@main
struct PedalHUDWatchRelayApp: App {
    @State private var model = WatchRelayModel()

    var body: some Scene {
        WindowGroup {
            WatchRelayView(model: model)
        }
    }
}

