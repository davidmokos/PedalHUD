import SwiftUI

extension OverlayHUDModel.Item {
    var displayValue: String {
        splitValue.value
    }

    var displayUnit: String? {
        splitValue.unit
    }

    var shortLabel: String {
        switch kind {
        case .watts:
            "POWER"
        case .heartRate:
            "HEART"
        }
    }

    var symbolName: String {
        switch kind {
        case .watts:
            "bolt.fill"
        case .heartRate:
            "heart.fill"
        }
    }

    var accentColors: [Color] {
        switch kind {
        case .watts:
            [
                Color(red: 0.10, green: 0.78, blue: 1.00),
                Color(red: 0.02, green: 0.42, blue: 0.95),
            ]
        case .heartRate:
            [
                Color(red: 1.00, green: 0.48, blue: 0.23),
                Color(red: 0.92, green: 0.17, blue: 0.29),
            ]
        }
    }

    private var splitValue: (value: String, unit: String?) {
        let components = value.split(separator: " ", maxSplits: 1).map(String.init)

        guard components.count == 2 else {
            return (value, nil)
        }

        return (components[0], components[1].uppercased())
    }
}
