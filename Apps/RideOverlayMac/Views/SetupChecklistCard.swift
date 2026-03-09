import SwiftUI
import RideOverlayCore

struct SetupChecklistCard: View {
    let model: RideOverlayAppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button("Activate Virtual Camera", action: installCameraExtension)
                Button("Request Camera Access", action: requestCameraAccess)
            }
            .controlSize(.small)

            if !model.cameraStatus.isEmpty {
                Text(model.cameraStatus)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor))
        )
    }

    private func requestCameraAccess() {
        Task {
            await model.requestCameraAccess()
        }
    }

    private func installCameraExtension() {
        Task {
            await model.installCameraExtension()
        }
    }
}
