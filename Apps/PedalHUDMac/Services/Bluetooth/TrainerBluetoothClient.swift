import CoreBluetooth
import Foundation
import PedalHUDCore

@MainActor
final class TrainerBluetoothClient: NSObject {
    var onMetrics: ((LiveMetrics) -> Void)?
    var onStateChange: ((String) -> Void)?
    var onPeripheralsChanged: (([DiscoveredPeripheral]) -> Void)?
    var onConnected: ((String) -> Void)?
    var onDisconnected: (() -> Void)?
    var onBluetoothStateChanged: ((Bool) -> Void)?

    private lazy var centralManager = CBCentralManager(delegate: self, queue: nil)
    private var connectedPeripheral: CBPeripheral?
    private var pendingPeripheral: CBPeripheral?
    private var shouldScanWhenPoweredOn = false
    private var latestCadence: Int?
    private var discoveredMap: [UUID: (peripheral: CBPeripheral, info: DiscoveredPeripheral)] = [:]

    private let fitnessMachineServiceUUID = CBUUID(string: "1826")
    private let cyclingPowerServiceUUID = CBUUID(string: "1818")
    private let indoorBikeDataCharacteristicUUID = CBUUID(string: "2AD2")
    private let cyclingPowerMeasurementCharacteristicUUID = CBUUID(string: "2A63")

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
        updateState("Searching for power meters")
        centralManager.scanForPeripherals(
            withServices: [
                fitnessMachineServiceUUID,
                cyclingPowerServiceUUID,
            ],
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

    private func handleMeasurement(_ measurement: LiveMetrics) {
        onMetrics?(measurement)
    }

    private func parseCyclingPowerMeasurement(_ data: Data) -> Int? {
        guard data.count >= 4 else {
            return nil
        }

        return readSInt16(from: data, at: 2)
    }

    private func parseIndoorBikeData(_ data: Data) -> LiveMetrics? {
        guard let flags = readUInt16(from: data, at: 0) else {
            return nil
        }

        var offset = 2
        offset += 2 // Instantaneous speed is always present.

        if flags & 0x0002 != 0 {
            offset += 2
        }

        if flags & 0x0004 != 0 {
            if let cadenceValue = readUInt16(from: data, at: offset) {
                latestCadence = Int(cadenceValue) / 2
            }

            offset += 2
        }

        if flags & 0x0008 != 0 {
            offset += 2
        }

        if flags & 0x0010 != 0 {
            offset += 3
        }

        if flags & 0x0020 != 0 {
            offset += 2
        }

        guard flags & 0x0040 != 0, let watts = readSInt16(from: data, at: offset) else {
            return nil
        }

        return LiveMetrics(
            watts: watts,
            heartRate: nil,
            cadence: latestCadence,
            source: .directBluetooth
        )
    }

    private func readUInt16(from data: Data, at index: Int) -> UInt16? {
        guard data.count >= index + 2 else {
            return nil
        }

        return UInt16(data[index]) | (UInt16(data[index + 1]) << 8)
    }

    private func readSInt16(from data: Data, at index: Int) -> Int? {
        guard let value = readUInt16(from: data, at: index) else {
            return nil
        }

        return Int(Int16(bitPattern: value))
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

extension TrainerBluetoothClient: @preconcurrency CBCentralManagerDelegate {
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
        let peripheralName = peripheral.name ?? advertisedName ?? "Trainer"
        let rssi = RSSI.intValue

        let discovered = DiscoveredPeripheral(id: peripheral.identifier, name: peripheralName, rssi: rssi)
        discoveredMap[peripheral.identifier] = (peripheral, discovered)
        notifyPeripheralsChanged()
        updateState("Found \(discoveredMap.count) trainer\(discoveredMap.count == 1 ? "" : "s")")
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        let name = peripheral.name ?? "trainer"
        updateState("Connected to \(name)")
        onConnected?(name)
        peripheral.discoverServices([
            fitnessMachineServiceUUID,
            cyclingPowerServiceUUID,
        ])
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

extension TrainerBluetoothClient: @preconcurrency CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            updateState("Service discovery failed: \(error.localizedDescription)")
            return
        }

        peripheral.services?.forEach { service in
            switch service.uuid {
            case fitnessMachineServiceUUID:
                peripheral.discoverCharacteristics([indoorBikeDataCharacteristicUUID], for: service)
            case cyclingPowerServiceUUID:
                peripheral.discoverCharacteristics([cyclingPowerMeasurementCharacteristicUUID], for: service)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            updateState("Characteristic discovery failed: \(error.localizedDescription)")
            return
        }

        service.characteristics?.forEach { characteristic in
            switch characteristic.uuid {
            case indoorBikeDataCharacteristicUUID, cyclingPowerMeasurementCharacteristicUUID:
                peripheral.setNotifyValue(true, for: characteristic)
            default:
                break
            }
        }

        updateState("Receiving power data")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            updateState("Update failed: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            return
        }

        switch characteristic.uuid {
        case cyclingPowerMeasurementCharacteristicUUID:
            guard let watts = parseCyclingPowerMeasurement(data) else {
                return
            }

            handleMeasurement(
                LiveMetrics(
                    watts: watts,
                    heartRate: nil,
                    cadence: latestCadence,
                    source: .directBluetooth
                )
            )
        case indoorBikeDataCharacteristicUUID:
            guard let measurement = parseIndoorBikeData(data) else {
                return
            }

            handleMeasurement(measurement)
        default:
            break
        }
    }
}
