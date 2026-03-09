import HealthKit
import Observation

@MainActor
@Observable
final class WorkoutManager {
    var heartRate = 0
    var sessionState = "Not started"

    @ObservationIgnored private let healthStore = HKHealthStore()

    func startWorkout() {
        sessionState = "Replace with an HKWorkoutSession and live heart-rate query."
        heartRate = 148
    }

    func stopWorkout() {
        sessionState = "Stopped"
    }
}

