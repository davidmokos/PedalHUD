@preconcurrency import AVFoundation
import CoreVideo
import Foundation
import PedalHUDCore

final class PedalHUDCameraCaptureSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "PedalHUDCameraCaptureSource.session")
    private let videoOutputQueue = DispatchQueue(label: "PedalHUDCameraCaptureSource.video")
    private let latestFrameLock = NSLock()
    private let cameraSelectionStore = SharedCameraSelectionStore()

    private var videoOutput = AVCaptureVideoDataOutput()
    private var currentInput: AVCaptureDeviceInput?
    private var latestPixelBuffer: CVPixelBuffer?
    private var hasConfiguredSession = false

    func start() throws {
        try sessionQueue.sync {
            try startSession()
        }
    }

    func startAsync() {
        sessionQueue.async { [self] in
            do {
                try startSession()
            } catch {
                NSLog(
                    "PedalHUDCameraExtension failed to start webcam capture asynchronously: %@",
                    error.localizedDescription
                )
            }
        }
    }

    func stop() {
        sessionQueue.sync {
            if session.isRunning {
                session.stopRunning()
            }
        }

        latestFrameLock.lock()
        latestPixelBuffer = nil
        latestFrameLock.unlock()
    }

    func currentFrame() -> CVPixelBuffer? {
        latestFrameLock.lock()
        let pixelBuffer = latestPixelBuffer
        latestFrameLock.unlock()
        return pixelBuffer
    }

    private func startSession() throws {
        if !hasConfiguredSession {
            try configureSession()
        }

        if !session.isRunning {
            session.startRunning()
        }
    }

    private func configureSession() throws {
        let device = try selectCaptureDevice()
        let input = try AVCaptureDeviceInput(device: device)

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        if let currentInput {
            session.removeInput(currentInput)
        }

        if session.canAddInput(input) {
            session.addInput(input)
            currentInput = input
        } else {
            session.commitConfiguration()
            throw NSError(
                domain: "PedalHUDCameraCaptureSource",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "The selected webcam cannot be attached to the virtual camera session."
                ]
            )
        }

        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        } else {
            session.commitConfiguration()
            throw NSError(
                domain: "PedalHUDCameraCaptureSource",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey: "The webcam output could not be attached to the virtual camera session."
                ]
            )
        }

        if let connection = videoOutput.connection(with: .video), connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }

        session.commitConfiguration()
        hasConfiguredSession = true
    }

    private func selectCaptureDevice() throws -> AVCaptureDevice {
        var preferredDeviceTypes: [AVCaptureDevice.DeviceType] = [
            .external,
            .builtInWideAngleCamera,
        ]

        if #available(macOS 14.0, *) {
            preferredDeviceTypes.insert(.continuityCamera, at: 1)
        }

        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: preferredDeviceTypes,
            mediaType: .video,
            position: .unspecified
        )

        let devices = discoverySession.devices.filter { device in
            !device.localizedName.localizedCaseInsensitiveContains("PedalHUD")
        }

        if let selectedCameraID = cameraSelectionStore.load(),
           let selectedCamera = devices.first(where: { $0.uniqueID == selectedCameraID }) {
            return selectedCamera
        }

        if let frontFacingDevice = devices.first(where: { $0.position == .front }) {
            return frontFacingDevice
        }

        if let firstDevice = devices.first {
            return firstDevice
        }

        throw NSError(
            domain: "PedalHUDCameraCaptureSource",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: "No physical webcam is available. Connect a camera and grant camera access before starting the virtual camera."
            ]
        )
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        latestFrameLock.lock()
        latestPixelBuffer = pixelBuffer
        latestFrameLock.unlock()
    }
}
