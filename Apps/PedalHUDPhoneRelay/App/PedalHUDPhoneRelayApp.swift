import SwiftUI

@main
struct PedalHUDPhoneRelayApp: App {
    @State private var model = PhoneRelayModel()

    var body: some Scene {
        WindowGroup {
            PhoneRelayView(model: model)
        }
    }
}

