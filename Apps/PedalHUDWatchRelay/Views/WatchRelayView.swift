import SwiftUI

struct WatchRelayView: View {
    let model: WatchRelayModel

    var body: some View {
        VStack(spacing: 14) {
            Text("PedalHUD")
                .font(.headline)

            Text("\(model.workoutManager.heartRate) bpm")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text(model.workoutManager.sessionState)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Start Workout", action: model.workoutManager.startWorkout)
                .buttonStyle(.borderedProminent)

            Button("Stop Workout", action: model.workoutManager.stopWorkout)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    WatchRelayView(model: WatchRelayModel())
}

