import RideOverlayCore
import SwiftUI

struct CameraPreviewCard: View {
    @Bindable var model: RideOverlayAppModel

    var body: some View {
        GroupBox("Camera Setup") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .bottom, spacing: 16) {
                    Picker("Camera", selection: $model.selectedCameraID) {
                        if model.availableCameras.isEmpty {
                            Text("No Cameras Found").tag(nil as String?)
                        } else {
                            ForEach(model.availableCameras) { camera in
                                Text(camera.localizedName).tag(Optional(camera.id))
                            }
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 360, alignment: .leading)
                    .disabled(model.availableCameras.isEmpty)
                    .onChange(of: model.selectedCameraID) { _, newValue in
                        model.selectCamera(id: newValue)
                    }

                    Button("Refresh Cameras", systemImage: "arrow.clockwise", action: model.refreshAvailableCameras)

                    Button(
                        model.isCameraPreviewRunning ? "Stop Preview" : "Start Preview",
                        systemImage: model.isCameraPreviewRunning ? "pause.circle" : "play.circle",
                        action: togglePreview
                    )

                    Picker("Preview Format", selection: $model.previewAspect) {
                        ForEach(OverlayPreviewAspect.allCases, id: \.self) { aspect in
                            Text(aspect.title).tag(aspect)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 170)
                }

                ZStack(alignment: .bottomLeading) {
                    CameraPreviewView(session: model.cameraPreviewSession)
                        .frame(maxWidth: model.previewAspect.maxWidth)
                        .aspectRatio(model.previewAspect.ratio, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(.white.opacity(0.08))
                        )

                    if !model.isCameraPreviewRunning {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.black.opacity(0.72))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "video.slash")
                                        .font(.system(size: 28, weight: .semibold))
                                    Text("Camera preview is not running")
                                        .font(.headline)
                                }
                                .foregroundStyle(.white.opacity(0.9))
                            )
                    }

                    Text(model.cameraPreviewStatus)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial.opacity(0.92))
                        .clipShape(Capsule())
                        .padding(18)
                }
                .frame(maxWidth: .infinity)

                Text("Choose the physical camera here. The virtual camera extension will use the same selection when a call app starts the stream.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func togglePreview() {
        if model.isCameraPreviewRunning {
            model.stopCameraPreview()
        } else {
            model.startCameraPreview()
        }
    }
}
