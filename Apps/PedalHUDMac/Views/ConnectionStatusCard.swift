import SwiftUI

struct ConnectionStatusCard: View {
    let model: PedalHUDAppModel

    var body: some View {
        VStack(spacing: 1) {
            PeripheralRow(
                icon: "bolt.fill",
                title: "Power Meter",
                statusText: model.trainerConnectionState,
                discoveredPeripherals: model.discoveredTrainers,
                connectedName: model.connectedTrainerName,
                isScanning: model.isScanningTrainers,
                isBluetoothAvailable: model.isBluetoothAvailable,
                onScan: { model.startTrainerScan() },
                onDisconnect: { model.disconnectTrainer() },
                onConnect: { id in model.connectTrainer(id: id) }
            )

            PeripheralRow(
                icon: "heart.fill",
                title: "Heart Rate",
                statusText: model.heartRateConnectionState,
                discoveredPeripherals: model.discoveredHeartRateMonitors,
                connectedName: model.connectedHeartRateMonitorName,
                isScanning: model.isScanningHeartRate,
                isBluetoothAvailable: model.isBluetoothAvailable,
                onScan: { model.startHeartRateScan() },
                onDisconnect: { model.disconnectHeartRateMonitor() },
                onConnect: { id in model.connectHeartRateMonitor(id: id) }
            )
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor))
        )
    }
}

private struct PeripheralRow: View {
    let icon: String
    let title: String
    let statusText: String
    let discoveredPeripherals: [DiscoveredPeripheral]
    let connectedName: String?
    let isScanning: Bool
    let isBluetoothAvailable: Bool
    let onScan: () -> Void
    let onDisconnect: () -> Void
    let onConnect: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.medium))
                    .frame(width: 80, alignment: .leading)

                if let connectedName {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text(connectedName)
                            .font(.subheadline)
                    }
                } else if isScanning {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Searching\u{2026}")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if !isBluetoothAvailable {
                    Text("Bluetooth is off")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if connectedName != nil {
                    Button("Disconnect", action: onDisconnect)
                        .controlSize(.small)
                } else if isScanning {
                    Button("Stop", action: onDisconnect)
                        .controlSize(.small)
                } else {
                    Button("Search", action: onScan)
                        .controlSize(.small)
                        .disabled(!isBluetoothAvailable)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if !discoveredPeripherals.isEmpty, connectedName == nil {
                Divider()
                    .padding(.leading, 36)

                VStack(spacing: 0) {
                    ForEach(discoveredPeripherals) { peripheral in
                        Button {
                            onConnect(peripheral.id)
                        } label: {
                            HStack {
                                Text(peripheral.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("\(peripheral.rssi) dBm")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.tertiary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 24)
            }
        }
    }
}
