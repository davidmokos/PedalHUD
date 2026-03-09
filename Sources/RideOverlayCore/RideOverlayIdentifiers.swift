import Foundation

public enum RideOverlayIdentifiers {
    public static let appGroup: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "RideOverlayAppGroup") as? String,
           !value.isEmpty {
            return value
        }
        return "group.cz.dctr.trainercast"
    }()
}
