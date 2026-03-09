import Foundation

public enum PedalHUDIdentifiers {
    public static let appGroup: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "PedalHUDAppGroup") as? String,
           !value.isEmpty {
            return value
        }
        return "group.cz.dctr.pedalhud"
    }()
}
