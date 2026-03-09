import SwiftUI

struct DashboardView: View {
    @Bindable var model: PedalHUDAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CameraPreviewCard(model: model)
            ConnectionStatusCard(model: model)
            SetupChecklistCard(model: model)
        }
        .padding(20)
    }
}

#Preview {
    DashboardView(model: PedalHUDAppModel())
}
