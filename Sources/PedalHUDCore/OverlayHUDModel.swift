import Foundation

public struct OverlayHUDModel: Equatable, Sendable {
    public struct Item: Equatable, Identifiable, Sendable {
        public enum Kind: String, Sendable {
            case watts
            case heartRate
        }

        public let kind: Kind
        public let title: String
        public let value: String

        public var id: Kind { kind }

        public init(kind: Kind, title: String, value: String) {
            self.kind = kind
            self.title = title
            self.value = value
        }
    }

    public let items: [Item]
    public let freshness: MetricFreshness
    public let placement: OverlayPlacement
    public let panelOpacity: Double
    public let accessibilityLabel: String

    public init(
        items: [Item],
        freshness: MetricFreshness,
        placement: OverlayPlacement,
        panelOpacity: Double,
        accessibilityLabel: String
    ) {
        self.items = items
        self.freshness = freshness
        self.placement = placement
        self.panelOpacity = panelOpacity
        self.accessibilityLabel = accessibilityLabel
    }
}

