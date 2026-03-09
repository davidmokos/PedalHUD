import Foundation
import PedalHUDCore
import WatchConnectivity

final class WatchMetricsReceiver: NSObject, WCSessionDelegate {
    var onMetrics: ((MetricsBridgeMessage) -> Void)?

    func start() {
        guard WCSession.isSupported() else {
            return
        }

        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let message = try? JSONDecoder().decode(MetricsBridgeMessage.self, from: messageData) else {
            return
        }

        onMetrics?(message)
    }
}

