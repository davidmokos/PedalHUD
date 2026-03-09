import Foundation

public struct SharedCameraSelectionStore {
    private let defaults: UserDefaults
    private let key = "pedalHUD.selectedCameraUniqueID"

    public init(appGroupIdentifier: String = PedalHUDIdentifiers.appGroup) {
        defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    public func load() -> String? {
        defaults.string(forKey: key)
    }

    public func save(_ uniqueID: String?) {
        if let uniqueID {
            defaults.set(uniqueID, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
