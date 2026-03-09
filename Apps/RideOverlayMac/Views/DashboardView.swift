import SwiftUI

struct DashboardView: View {
    let model: RideOverlayAppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Ride Overlay")
                    .font(.largeTitle.weight(.semibold))

                Text("Starter scaffold for a virtual camera that overlays watts and heart rate on top of your ride video.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                ConnectionStatusCard(model: model)
                CameraPreviewCard(model: model)
                MetricsPreviewCard(
                    metrics: model.currentMetrics,
                    configuration: model.overlayConfiguration,
                    session: model.cameraPreviewSession,
                    isCameraPreviewRunning: model.isCameraPreviewRunning,
                    previewAspect: model.previewAspect
                )
                SetupChecklistCard(model: model)
            }
            .padding(28)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.teal.opacity(0.38),
                    Color.orange.opacity(0.18),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    DashboardView(model: RideOverlayAppModel())
}
