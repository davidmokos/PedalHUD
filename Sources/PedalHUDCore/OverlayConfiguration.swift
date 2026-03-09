import Foundation

public struct OverlayConfiguration: Codable, Equatable, Sendable {
    public var placement: OverlayPlacement
    public var showsWatts: Bool
    public var showsHeartRate: Bool
    public var mirrorsOutput: Bool
    public var cornerInset: Double
    public var panelOpacity: Double
    public var agingAfter: TimeInterval
    public var staleAfter: TimeInterval

    public init(
        placement: OverlayPlacement = .bottomCenter,
        showsWatts: Bool = true,
        showsHeartRate: Bool = true,
        mirrorsOutput: Bool = false,
        cornerInset: Double = 20,
        panelOpacity: Double = 0.9,
        agingAfter: TimeInterval = 1,
        staleAfter: TimeInterval = 3
    ) {
        self.placement = placement
        self.showsWatts = showsWatts
        self.showsHeartRate = showsHeartRate
        self.mirrorsOutput = mirrorsOutput
        self.cornerInset = cornerInset
        self.panelOpacity = panelOpacity
        self.agingAfter = agingAfter
        self.staleAfter = staleAfter
    }

    public static let defaultConfiguration = Self()
}
