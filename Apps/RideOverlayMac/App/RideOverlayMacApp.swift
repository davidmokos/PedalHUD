import SwiftUI
import Sparkle

@main
struct RideOverlayMacApp: App {
    @State private var model = RideOverlayAppModel()
    @StateObject private var updaterController = UpdaterController()

    var body: some Scene {
        Window("Ride Overlay", id: "dashboard") {
            DashboardView(model: model)
                .frame(width: 580)
                .task { updaterController.start() }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates\u{2026}") {
                    updaterController.checkForUpdates()
                }
                .disabled(!updaterController.canCheckForUpdates)
            }
        }
    }
}

