import CoreGraphics

public enum OverlayPreviewAspect: String, CaseIterable, Sendable {
    case square
    case widescreen

    public var title: String {
        switch self {
        case .square:
            "1:1"
        case .widescreen:
            "16:9"
        }
    }

    public var ratio: CGFloat {
        switch self {
        case .square:
            1
        case .widescreen:
            16.0 / 9.0
        }
    }

    public var maxWidth: CGFloat {
        switch self {
        case .square:
            360
        case .widescreen:
            560
        }
    }
}
