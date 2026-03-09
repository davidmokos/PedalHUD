import SwiftUI
import Sparkle

@main
struct PedalHUDMacApp: App {
    @State private var model = PedalHUDAppModel()
    @StateObject private var updaterController = UpdaterController()

    var body: some Scene {
        Window("PedalHUD", id: "dashboard") {
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

