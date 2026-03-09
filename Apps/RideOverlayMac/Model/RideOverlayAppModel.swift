import Foundation
import Observation
import RideOverlayCore
import AVFoundation

@MainActor
@Observable
final class RideOverlayAppModel {
    var currentMetrics = LiveMetrics.empty
    var overlayConfiguration = OverlayConfiguration.defaultConfiguration
    var trainerConnectionState = "Ready to scan"
    var heartRateConnectionState = "Ready to scan"
    var relayStatus = "Shared metrics store ready"
    var cameraStatus = "Move the built app to /Applications, then activate the virtual camera"
    var cameraPreviewStatus = "Grant camera access to preview and choose a camera"
    var availableCameras: [CameraDeviceOption] = []
    var selectedCameraID: String?
    var previewAspect = OverlayPreviewAspect.square
    var isCameraPreviewRunning = false

    @ObservationIgnored private let metricsWriter: SharedMetricsWriter
    @ObservationIgnored private let trainerClient: TrainerBluetoothClient
    @ObservationIgnored private let heartRateClient: HeartRateBluetoothClient
    @ObservationIgnored private let overlayConfigurationStore: SharedOverlayConfigurationStore
    @ObservationIgnored private let cameraSelectionStore: SharedCameraSelectionStore
    @ObservationIgnored private let cameraPreviewController: CameraPreviewController
    @ObservationIgnored private let mockFeed = MockMetricsFeed()
    @ObservationIgnored private var cameraExtensionInstaller: CameraExtensionInstaller?
    @ObservationIgnored private var simulationTask: Task<Void, Never>?

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

        self.heartRateClient.onStateChange = { [weak self] state in
            self?.heartRateConnectionState = state
        }

        self.heartRateClient.onHeartRate = { [weak self] heartRate in
            self?.handleHeartRate(heartRate)
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
    }

    func startSimulation() {
        simulationTask?.cancel()
        trainerClient.stop()
        trainerConnectionState = "Using simulated trainer feed"

        simulationTask = Task {
            for await metrics in mockFeed.stream(interval: .seconds(1)) {
                currentMetrics = metrics
                await persistMetrics(metrics, status: "Streaming simulated watts")
            }
        }
    }

    func stopSimulation() {
        simulationTask?.cancel()
        simulationTask = nil
        relayStatus = "Preview paused"
    }

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

    func connectTrainer() async {
        stopSimulation()
        trainerClient.start()
    }

    func connectHeartRateMonitor() async {
        stopSimulation()
        heartRateClient.start()
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
