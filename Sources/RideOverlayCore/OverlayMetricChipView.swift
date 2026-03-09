import SwiftUI

struct OverlayMetricChipView: View {
    let item: OverlayHUDModel.Item

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(item.displayValue)
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)

            if let unit = item.displayUnit {
                Text(unit)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .padding(.bottom, 2)
            }
        }
        .frame(minWidth: 100, minHeight: 60, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            item.accentColors[0],
                            item.accentColors.last?.opacity(0.92) ?? item.accentColors[0].opacity(0.92),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}
