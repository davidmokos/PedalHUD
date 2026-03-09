import Observation

@MainActor
@Observable
final class WatchRelayModel {
    var relayStatus = "Ready"
    var workoutManager = WorkoutManager()
}

