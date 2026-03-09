import SwiftUI

struct OverlayHeroMetricView: View {
    let item: OverlayHUDModel.Item

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.24),
                            .white.opacity(0.04),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.screen)

            VStack(alignment: .leading, spacing: 7) {
                Label(item.shortLabel, systemImage: item.symbolName)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundStyle(.white.opacity(0.82))

                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(item.displayValue)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)

                    if let unit = item.displayUnit {
                        Text(unit)
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.16))
        )
        .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
    }
}
