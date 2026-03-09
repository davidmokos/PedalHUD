import SwiftUI

struct OverlayMetricChipView: View {
    let item: OverlayHUDModel.Item

    var body: some View {
        HStack(spacing: 9) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: item.accentColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
                .overlay(
                    Image(systemName: item.symbolName)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.uppercased())
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.displayValue)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let unit = item.displayUnit {
                        Text(unit)
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(.white.opacity(0.72))
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
        .fixedSize(horizontal: false, vertical: true)
    }
}
