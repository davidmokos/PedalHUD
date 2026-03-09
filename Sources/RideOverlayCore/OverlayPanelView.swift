import SwiftUI

public struct OverlayPanelView: View {
    public let model: OverlayHUDModel

    public init(model: OverlayHUDModel) {
        self.model = model
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(metricItems) { item in
                OverlayMetricChipView(item: item)
                    .layoutPriority(1)
            }
        }
        .padding(8)
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
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var metricItems: [OverlayHUDModel.Item] {
        let items = model.items
        return items.isEmpty ? [OverlayHUDModel.Item(kind: .watts, title: "Watts", value: "-- W")] : items
    }
}
