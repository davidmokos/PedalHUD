import SwiftUI

public struct OverlayPanelView: View {
    public let model: OverlayHUDModel

    public init(model: OverlayHUDModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 10) {
            OverlayStatusBadgeView(freshness: model.freshness)

            OverlayHeroMetricView(item: heroItem)
                .layoutPriority(1)

            ForEach(secondaryItems) { item in
                OverlayMetricChipView(item: item)
                    .layoutPriority(1)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(max(model.panelOpacity, 0.78)),
                            Color(red: 0.05, green: 0.07, blue: 0.11).opacity(max(model.panelOpacity, 0.88)),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        )
        .shadow(color: .black.opacity(0.28), radius: 22, y: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var heroItem: OverlayHUDModel.Item {
        model.items.first ?? OverlayHUDModel.Item(kind: .watts, title: "Watts", value: "-- W")
    }

    private var secondaryItems: [OverlayHUDModel.Item] {
        Array(model.items.dropFirst())
    }
}
