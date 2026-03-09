import SwiftUI

public struct OverlayPanelView: View {
    public let model: OverlayHUDModel

    public init(model: OverlayHUDModel) {
        self.model = model
    }

    public var body: some View {
        if !model.items.isEmpty {
            HStack(spacing: 8) {
                ForEach(model.items) { item in
                    OverlayMetricChipView(item: item)
                        .layoutPriority(1)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
        }
    }
}
