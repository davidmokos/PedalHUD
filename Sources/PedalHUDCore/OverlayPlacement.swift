import Foundation

public enum OverlayPlacement: String, Codable, CaseIterable, Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomCenter
    case bottomTrailing
}
