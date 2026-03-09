import SwiftUI

struct OverlayStatusBadgeView: View {
    let freshness: MetricFreshness

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(backgroundColor)
                .frame(width: 8, height: 8)

            Text(title)
                .lineLimit(1)
        }
        .font(.system(.caption2, design: .rounded).weight(.bold))
        .foregroundStyle(.white.opacity(0.94))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(.black.opacity(0.26))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        )
        .fixedSize()
        .accessibilityHidden(true)
    }

    private var title: String {
        switch freshness {
        case .live:
            "LIVE"
        case .aging:
            "RECENT"
        case .stale:
            "STALE"
        }
    }

    private var backgroundColor: Color {
        switch freshness {
        case .live:
            Color(red: 0.09, green: 0.78, blue: 0.42)
        case .aging:
            Color(red: 0.95, green: 0.66, blue: 0.12)
        case .stale:
            Color(red: 0.95, green: 0.27, blue: 0.22)
        }
    }
}
