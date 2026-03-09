import CoreBluetooth
import Foundation

@MainActor
final class HeartRateBluetoothClient: NSObject {
    var onHeartRate: ((Int) -> Void)?
    var onStateChange: ((String) -> Void)?
    var onPeripheralsChanged: (([DiscoveredPeripheral]) -> Void)?
    var onConnected: ((String) -> Void)?
    var onDisconnected: (() -> Void)?
    var onBluetoothStateChanged: ((Bool) -> Void)?

    private lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    private var connectedPeripheral: CBPeripheral?
    private var pendingPeripheral: CBPeripheral?
    private var shouldScanWhenPoweredOn = false
    private var discoveredMap: [UUID: (peripheral: CBPeripheral, info: DiscoveredPeripheral)] = [:]

    private let heartRateServiceUUID = CBUUID(string: "180D")
    private let heartRateMeasurementCharacteristicUUID = CBUUID(string: "2A37")

    func initializeBluetooth() {
        _ = centralManager
    }

    func start() {
        shouldScanWhenPoweredOn = true
        _ = centralManager

        guard centralManager.state == .poweredOn else {
            updateState(centralStateDescription(centralManager.state))
            return
        }

        startScan()
    }

    func stop() {
        shouldScanWhenPoweredOn = false
        centralManager.stopScan()
        discoveredMap.removeAll()
        onPeripheralsChanged?([])

        if let connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        } else if let pendingPeripheral {
            centralManager.cancelPeripheralConnection(pendingPeripheral)
        } else {
            updateState("Not connected")
        }
    }

    func connectPeripheral(id: UUID) {
        guard let entry = discoveredMap[id] else { return }
        connect(to: entry.peripheral, name: entry.info.name)
    }

    private func startScan() {
        guard connectedPeripheral == nil, pendingPeripheral == nil else {
            return
        }

        discoveredMap.removeAll()
        onPeripheralsChanged?([])
        updateState("Searching for heart rate monitors")
        centralManager.scanForPeripherals(
            withServices: [heartRateServiceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false,
            ]
        )
    }

    private func connect(to peripheral: CBPeripheral, name: String) {
        pendingPeripheral = peripheral
        peripheral.delegate = self
        centralManager.stopScan()
        updateState("Connecting to \(name)")
        centralManager.connect(peripheral)
    }

    private func parseHeartRateMeasurement(_ data: Data) -> Int? {
        guard data.count >= 2 else {
            return nil
        }

        let flags = data[0]

        if flags & 0x01 != 0 {
            guard data.count >= 3 else {
                return nil
            }

            return Int(UInt16(data[1]) | (UInt16(data[2]) << 8))
        }

        return Int(data[1])
    }

    private func updateState(_ state: String) {
        onStateChange?(state)
    }

    private func notifyPeripheralsChanged() {
        let sorted = discoveredMap.values.map(\.info).sorted { $0.rssi > $1.rssi }
        onPeripheralsChanged?(sorted)
    }

    private func centralStateDescription(_ state: CBManagerState) -> String {
        switch state {
        case .unknown:
            "Bluetooth state is unknown"
        case .resetting:
            "Bluetooth is resetting"
        case .unsupported:
            "Bluetooth is unsupported on this Mac"
        case .unauthorized:
            "Bluetooth access is denied"
        case .poweredOff:
            "Turn on Bluetooth"
        case .poweredOn:
            "Bluetooth is ready"
        @unknown default:
            "Bluetooth is unavailable"
        }
    }
}

extension HeartRateBluetoothClient: @preconcurrency CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateState(centralStateDescription(central.state))
        onBluetoothStateChanged?(central.state == .poweredOn)

        if central.state == .poweredOn, shouldScanWhenPoweredOn {
            startScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard connectedPeripheral == nil, pendingPeripheral == nil else {
            return
        }

        let advertisedName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let peripheralName = peripheral.name ?? advertisedName ?? "Heart Rate Monitor"
        let rssi = RSSI.intValue

        let discovered = DiscoveredPeripheral(id: peripheral.identifier, name: peripheralName, rssi: rssi)
        discoveredMap[peripheral.identifier] = (peripheral, discovered)
        notifyPeripheralsChanged()
        updateState("Found \(discoveredMap.count) heart rate monitor\(discoveredMap.count == 1 ? "" : "s")")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        let name = peripheral.name ?? "heart rate monitor"
        updateState("Connected to \(name)")
        onConnected?(name)
        peripheral.discoverServices([heartRateServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        pendingPeripheral = nil
        shouldScanWhenPoweredOn = false

        if let error {
            updateState("Disconnected: \(error.localizedDescription)")
        } else {
            updateState("Disconnected")
        }

        onDisconnected?()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        pendingPeripheral = nil
        updateState(error?.localizedDescription ?? "Failed to connect")
        onDisconnected?()
    }
}

extension HeartRateBluetoothClient: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            updateState("Service discovery failed: \(error.localizedDescription)")
            return
        }

        peripheral.services?.forEach { service in
            guard service.uuid == heartRateServiceUUID else {
                return
            }

            peripheral.discoverCharacteristics([heartRateMeasurementCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            updateState("Characteristic discovery failed: \(error.localizedDescription)")
            return
        }

        service.characteristics?.forEach { characteristic in
            guard characteristic.uuid == heartRateMeasurementCharacteristicUUID else {
                return
            }

            peripheral.setNotifyValue(true, for: characteristic)
        }

        updateState("Receiving heart rate")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            updateState("Update failed: \(error.localizedDescription)")
            return
        }

        guard characteristic.uuid == heartRateMeasurementCharacteristicUUID,
              let data = characteristic.value,
              let heartRate = parseHeartRateMeasurement(data) else {
            return
        }

        onHeartRate?(heartRate)
    }
}
