import AVFoundation
import PedalHUDCore
import SwiftUI

struct CameraPreviewCard: View {
    @Bindable var model: PedalHUDAppModel

    private let builder = OverlayHUDModelBuilder()

    var body: some View {
        let hud = builder.build(metrics: model.currentMetrics, configuration: model.overlayConfiguration)

        VStack(spacing: 0) {
            cameraContent(
                with: OverlayPanelView(model: hud)
                    .frame(width: overlayWidth, alignment: alignment(for: hud.placement))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: hud.placement))
                    .padding(model.overlayConfiguration.cornerInset)
            )
            .scaleEffect(x: model.overlayConfiguration.mirrorsOutput ? -1 : 1, y: 1)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 10,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 10,
                    style: .continuous
                )
            )

            controlsBar
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor))
        )
    }

    @ViewBuilder
    private func cameraContent(with hudOverlay: some View) -> some View {
        // Fixed square container; 16:9 letterboxes inside it.
        Color(nsColor: .windowBackgroundColor)
            .aspectRatio(1, contentMode: .fill)
            .fixedSize(horizontal: false, vertical: true)
            .overlay {
                Group {
                    if model.isCameraPreviewRunning {
                        CameraPreviewView(session: model.cameraPreviewSession)
                    } else {
                        Rectangle()
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .overlay {
                                VStack(spacing: 6) {
                                    Image(systemName: "video.slash")
                                        .font(.title2)
                                    Text("Camera preview is off")
                                        .font(.subheadline)
                                }
                                .foregroundStyle(.secondary)
                            }
                    }
                }
                .aspectRatio(model.previewAspect.ratio, contentMode: .fit)
                .overlay { hudOverlay }
            }
    }

    private var controlsBar: some View {
        HStack(spacing: 10) {
            Picker("Camera", selection: $model.selectedCameraID) {
                if model.availableCameras.isEmpty {
                    Text("No Cameras").tag(nil as String?)
                } else {
                    ForEach(model.availableCameras) { camera in
                        Text(camera.localizedName).tag(Optional(camera.id))
                    }
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: 220)
            .disabled(model.availableCameras.isEmpty)
            .onChange(of: model.selectedCameraID) { _, newValue in
                model.selectCamera(id: newValue)
            }

            Picker("Format", selection: $model.previewAspect) {
                ForEach(OverlayPreviewAspect.allCases, id: \.self) { aspect in
                    Text(aspect.title).tag(aspect)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .frame(width: 100)

            Spacer()

            Button {
                model.toggleMirrorOutput()
            } label: {
                Image(systemName: "arrow.left.and.right.text.vertical")
            }
            .help(model.overlayConfiguration.mirrorsOutput ? "Unmirror" : "Mirror")

            Button {
                if model.isCameraPreviewRunning {
                    model.stopCameraPreview()
                } else {
                    model.startCameraPreview()
                }
            } label: {
                Image(systemName: model.isCameraPreviewRunning ? "pause.fill" : "play.fill")
            }
            .help(model.isCameraPreviewRunning ? "Stop preview" : "Start preview")
        }
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var overlayWidth: CGFloat {
        switch model.previewAspect {
        case .square:
            220
        case .widescreen:
            260
        }
    }

    private func alignment(for placement: OverlayPlacement) -> Alignment {
        switch placement {
        case .topLeading: .topLeading
        case .topTrailing: .topTrailing
        case .bottomLeading: .bottomLeading
        case .bottomCenter: .bottom
        case .bottomTrailing: .bottomTrailing
        }
    }
}
