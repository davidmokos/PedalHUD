import Foundation
import Observation
import RideOverlayCore
import AVFoundation

@MainActor
@Observable
final class RideOverlayAppModel {
    var currentMetrics = LiveMetrics.empty
    var overlayConfiguration = OverlayConfiguration.defaultConfiguration
    var trainerConnectionState = "Not connected"
    var heartRateConnectionState = "Not connected"
    var relayStatus = "Shared metrics store ready"
    var cameraStatus = "Move the built app to /Applications, then activate the virtual camera"
    var cameraPreviewStatus = "Grant camera access to preview and choose a camera"
    var availableCameras: [CameraDeviceOption] = []
    var selectedCameraID: String?
    var previewAspect = OverlayPreviewAspect.square
    var isCameraPreviewRunning = false

    var discoveredTrainers: [DiscoveredPeripheral] = []
    var discoveredHeartRateMonitors: [DiscoveredPeripheral] = []
    var connectedTrainerName: String?
    var connectedHeartRateMonitorName: String?
    var isScanningTrainers = false
    var isScanningHeartRate = false
    var isBluetoothAvailable = false

    @ObservationIgnored private let metricsWriter: SharedMetricsWriter
    @ObservationIgnored private let trainerClient: TrainerBluetoothClient
    @ObservationIgnored private let heartRateClient: HeartRateBluetoothClient
    @ObservationIgnored private let overlayConfigurationStore: SharedOverlayConfigurationStore
    @ObservationIgnored private let cameraSelectionStore: SharedCameraSelectionStore
    @ObservationIgnored private let cameraPreviewController: CameraPreviewController
    @ObservationIgnored private var cameraExtensionInstaller: CameraExtensionInstaller?

    init(
        metricsWriter: SharedMetricsWriter = SharedMetricsWriter(),
        trainerClient: TrainerBluetoothClient = TrainerBluetoothClient(),
        heartRateClient: HeartRateBluetoothClient = HeartRateBluetoothClient(),
        overlayConfigurationStore: SharedOverlayConfigurationStore = SharedOverlayConfigurationStore(),
        cameraSelectionStore: SharedCameraSelectionStore = SharedCameraSelectionStore(),
        cameraPreviewController: CameraPreviewController = CameraPreviewController()
    ) {
        self.metricsWriter = metricsWriter
        self.trainerClient = trainerClient
        self.heartRateClient = heartRateClient
        self.overlayConfigurationStore = overlayConfigurationStore
        self.cameraSelectionStore = cameraSelectionStore
        self.cameraPreviewController = cameraPreviewController

        self.trainerClient.onStateChange = { [weak self] state in
            self?.trainerConnectionState = state
        }

        self.trainerClient.onMetrics = { [weak self] metrics in
            self?.handleTrainerMetrics(metrics)
        }

        self.trainerClient.onPeripheralsChanged = { [weak self] peripherals in
            self?.discoveredTrainers = peripherals
        }

        self.trainerClient.onConnected = { [weak self] name in
            self?.connectedTrainerName = name
            self?.isScanningTrainers = false
            self?.discoveredTrainers = []
        }

        self.trainerClient.onDisconnected = { [weak self] in
            self?.connectedTrainerName = nil
            self?.isScanningTrainers = false
            self?.discoveredTrainers = []
            self?.clearTrainerMetrics()
        }

        self.trainerClient.onBluetoothStateChanged = { [weak self] available in
            self?.isBluetoothAvailable = available
        }

        self.heartRateClient.onStateChange = { [weak self] state in
            self?.heartRateConnectionState = state
        }

        self.heartRateClient.onHeartRate = { [weak self] heartRate in
            self?.handleHeartRate(heartRate)
        }

        self.heartRateClient.onPeripheralsChanged = { [weak self] peripherals in
            self?.discoveredHeartRateMonitors = peripherals
        }

        self.heartRateClient.onConnected = { [weak self] name in
            self?.connectedHeartRateMonitorName = name
            self?.isScanningHeartRate = false
            self?.discoveredHeartRateMonitors = []
        }

        self.heartRateClient.onDisconnected = { [weak self] in
            self?.connectedHeartRateMonitorName = nil
            self?.isScanningHeartRate = false
            self?.discoveredHeartRateMonitors = []
            self?.clearHeartRateMetrics()
        }

        self.heartRateClient.onBluetoothStateChanged = { [weak self] available in
            self?.isBluetoothAvailable = available
        }

        self.cameraPreviewController.onStateChange = { [weak self] state, isRunning in
            self?.cameraPreviewStatus = state
            self?.isCameraPreviewRunning = isRunning
        }

        self.overlayConfiguration = overlayConfigurationStore.load()
        selectedCameraID = cameraSelectionStore.load()
        refreshAvailableCameras()

        let authorizationCoordinator = CameraAuthorizationCoordinator()

        switch authorizationCoordinator.authorizationStatus() {
        case .authorized:
            startCameraPreview()
        case .denied, .restricted:
            cameraPreviewStatus = "Camera access is denied. Allow access in System Settings to preview the selected camera."
        case .notDetermined:
            break
        @unknown default:
            cameraPreviewStatus = "Camera access state is unknown."
        }

        trainerClient.initializeBluetooth()
    }

    // MARK: - Trainer scanning

    func startTrainerScan() {
        isScanningTrainers = true
        trainerClient.start()
    }

    func connectTrainer(id: UUID) {
        trainerClient.connectPeripheral(id: id)
    }

    func disconnectTrainer() {
        isScanningTrainers = false
        connectedTrainerName = nil
        discoveredTrainers = []
        trainerClient.stop()
        clearTrainerMetrics()
    }

    // MARK: - Heart rate scanning

    func startHeartRateScan() {
        isScanningHeartRate = true
        heartRateClient.start()
    }

    func connectHeartRateMonitor(id: UUID) {
        heartRateClient.connectPeripheral(id: id)
    }

    func disconnectHeartRateMonitor() {
        isScanningHeartRate = false
        connectedHeartRateMonitorName = nil
        discoveredHeartRateMonitors = []
        heartRateClient.stop()
        clearHeartRateMetrics()
    }

    // MARK: - Camera

    func requestCameraAccess() async {
        let coordinator = CameraAuthorizationCoordinator()
        let granted = await coordinator.requestAccess()

        if granted {
            refreshAvailableCameras()
            startCameraPreview()
        } else {
            isCameraPreviewRunning = false
            cameraPreviewStatus = "Camera access denied"
        }
    }

    func refreshAvailableCameras() {
        availableCameras = CameraDeviceCatalog.availableCameras()

        guard !availableCameras.isEmpty else {
            selectedCameraID = nil
            cameraSelectionStore.save(nil)
            cameraPreviewStatus = "No physical camera is available on this Mac."
            return
        }

        if let selectedCameraID, availableCameras.contains(where: { $0.id == selectedCameraID }) {
            return
        }

        selectedCameraID = availableCameras.first?.id
        cameraSelectionStore.save(selectedCameraID)
    }

    func selectCamera(id: String?) {
        selectedCameraID = id
        cameraSelectionStore.save(id)

        if CameraAuthorizationCoordinator().authorizationStatus() == .authorized {
            startCameraPreview()
        }
    }

    func startCameraPreview() {
        guard CameraAuthorizationCoordinator().authorizationStatus() == .authorized else {
            cameraPreviewStatus = "Grant camera access to preview and choose a camera"
            isCameraPreviewRunning = false
            return
        }

        refreshAvailableCameras()
        cameraPreviewController.startPreview(cameraID: selectedCameraID)
    }

    func toggleMirrorOutput() {
        overlayConfiguration.mirrorsOutput.toggle()
        overlayConfigurationStore.save(overlayConfiguration)
    }

    func stopCameraPreview() {
        cameraPreviewController.stopPreview()
    }

    var cameraPreviewSession: AVCaptureSession {
        cameraPreviewController.session
    }

    func installCameraExtension() async {
        let installer = CameraExtensionInstaller()
        installer.onStatusChange = { [weak self] status in
            self?.cameraStatus = status
        }
        cameraExtensionInstaller = installer

        do {
            cameraStatus = "Submitting virtual camera activation request..."
            cameraStatus = try await installer.install()
        } catch {
            cameraStatus = error.localizedDescription
        }

        cameraExtensionInstaller = nil
    }

    // MARK: - Metrics handling

    private func handleTrainerMetrics(_ metrics: LiveMetrics) {
        let mergedMetrics = LiveMetrics(
            watts: metrics.watts,
            heartRate: currentMetrics.heartRate,
            cadence: metrics.cadence,
            source: metrics.source,
            receivedAt: metrics.receivedAt
        )
        currentMetrics = mergedMetrics

        Task {
            await persistMetrics(
                mergedMetrics,
                status: relayStatusDescription(for: mergedMetrics)
            )
        }
    }

    private func handleHeartRate(_ heartRate: Int) {
        let mergedMetrics = LiveMetrics(
            watts: currentMetrics.watts,
            heartRate: heartRate,
            cadence: currentMetrics.cadence,
            source: .directBluetooth,
            receivedAt: .now
        )
        currentMetrics = mergedMetrics

        Task {
            await persistMetrics(
                mergedMetrics,
                status: relayStatusDescription(for: mergedMetrics)
            )
        }
    }

    private func clearTrainerMetrics() {
        let cleared = LiveMetrics(
            watts: nil,
            heartRate: currentMetrics.heartRate,
            cadence: nil,
            source: currentMetrics.source,
            receivedAt: .now
        )
        currentMetrics = cleared
        Task { await persistMetrics(cleared, status: relayStatusDescription(for: cleared)) }
    }

    private func clearHeartRateMetrics() {
        let cleared = LiveMetrics(
            watts: currentMetrics.watts,
            heartRate: nil,
            cadence: currentMetrics.cadence,
            source: currentMetrics.source,
            receivedAt: .now
        )
        currentMetrics = cleared
        Task { await persistMetrics(cleared, status: relayStatusDescription(for: cleared)) }
    }

    private func persistMetrics(_ metrics: LiveMetrics, status: String) async {
        do {
            try await metricsWriter.persist(metrics)
            relayStatus = status
        } catch {
            relayStatus = "Shared metrics write failed: \(error.localizedDescription)"
        }
    }

    private func relayStatusDescription(for metrics: LiveMetrics) -> String {
        switch (metrics.watts != nil, metrics.heartRate != nil) {
        case (true, true):
            "Shared live watts and heart rate with the virtual camera"
        case (true, false):
            "Shared live watts with the virtual camera"
        case (false, true):
            "Shared live heart rate with the virtual camera"
        case (false, false):
            "Shared metrics store ready"
        }
    }
}
