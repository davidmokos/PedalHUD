@preconcurrency import AVFoundation
import Foundation

@MainActor
final class CameraPreviewController {
    var onStateChange: ((String, Bool) -> Void)?

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "PedalHUDMac.CameraPreviewController")
    private var currentInput: AVCaptureDeviceInput?

    func startPreview(cameraID: String?) {
        guard let device = CameraDeviceCatalog.device(for: cameraID) else {
            onStateChange?("No physical camera is available on this Mac.", false)
            return
        }

        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            do {
                try self.configureSession(for: device)

                if !self.session.isRunning {
                    self.session.startRunning()
                }

                DispatchQueue.main.async {
                    self.onStateChange?("Previewing \(device.localizedName)", true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.onStateChange?("Camera preview failed: \(error.localizedDescription)", false)
                }
            }
        }
    }

    func stopPreview() {
        sessionQueue.async { [weak self] in
            guard let self else {
                return
            }

            if self.session.isRunning {
                self.session.stopRunning()
            }

            if let input = self.currentInput {
                self.session.beginConfiguration()
                self.session.removeInput(input)
                self.session.commitConfiguration()
                self.currentInput = nil
            }

            DispatchQueue.main.async {
                self.onStateChange?("Preview stopped", false)
            }
        }
    }

    private func configureSession(for device: AVCaptureDevice) throws {
        if currentInput?.device.uniqueID == device.uniqueID {
            return
        }

        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        if let currentInput {
            session.removeInput(currentInput)
        }

        guard session.canAddInput(input) else {
            session.commitConfiguration()
            throw NSError(
                domain: "PedalHUDMac.CameraPreviewController",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "The selected camera cannot be attached to the preview session."
                ]
            )
        }

        session.addInput(input)
        currentInput = input
        session.commitConfiguration()
    }
}
