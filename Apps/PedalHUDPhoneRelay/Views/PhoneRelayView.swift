import SwiftUI

struct PhoneRelayView: View {
    let model: PhoneRelayModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Watch to Mac Relay")
                    .font(.largeTitle.weight(.semibold))

                Text("This app forwards live metrics from watchOS to the Mac host app. The transport is currently a simple HTTP placeholder.")
                    .foregroundStyle(.secondary)

                LabeledContent("Heart Rate", value: model.currentMetrics.heartRate.map(String.init) ?? "--")
                LabeledContent("Relay Status", value: model.relayStatus)

                Button("Send Preview Payload", systemImage: "paperplane.fill", action: sendPreviewSample)
                    .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("PedalHUD Relay")
        }
    }

    private func sendPreviewSample() {
        Task {
            await model.sendPreviewSample()
        }
    }
}

#Preview {
    PhoneRelayView(model: PhoneRelayModel())
}

