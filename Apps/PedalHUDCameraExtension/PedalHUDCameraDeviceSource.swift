import AVFoundation
import CoreMediaIO
import Foundation
import IOKit.audio
import PedalHUDCore

private final class StreamEndpoint: @unchecked Sendable {
    let stream: CMIOExtensionStream

    init(stream: CMIOExtensionStream) {
        self.stream = stream
    }
}

final class PedalHUDCameraDeviceSource: NSObject, CMIOExtensionDeviceSource {
    private(set) var device: CMIOExtensionDevice!

    private let frameDuration = CMTime(value: 1, timescale: 30)
    private let metricsReader = PedalHUDMetricsReader()
    private let overlayConfigurationStore = SharedOverlayConfigurationStore()
    private let renderer = PedalHUDFrameRenderer()
    private let captureSource = PedalHUDCameraCaptureSource()
    private let streamingQueue = DispatchQueue(label: "PedalHUDCameraDeviceSource.streaming")
    private var streamSource: PedalHUDCameraStreamSource!
    private var videoDescription: CMFormatDescription!
    private var streamTimer: DispatchSourceTimer?

    init(localizedName: String) {
        super.init()

        let deviceID = UUID(uuidString: "F2E3BDF1-0A91-4C33-BFD8-A86231F0FA9B") ?? UUID()
        let streamID = UUID(uuidString: "89E04765-9F34-4637-A66C-2A488D711B1F") ?? UUID()
        let dimensions = CMVideoDimensions(width: 1280, height: 720)

        device = CMIOExtensionDevice(
            localizedName: localizedName,
            deviceID: deviceID,
            legacyDeviceID: nil,
            source: self
        )

        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: dimensions.width,
            height: dimensions.height,
            extensions: nil,
            formatDescriptionOut: &videoDescription
        )

        let streamFormat = CMIOExtensionStreamFormat(
            formatDescription: videoDescription,
            maxFrameDuration: frameDuration,
            minFrameDuration: frameDuration,
            validFrameDurations: nil
        )

        streamSource = PedalHUDCameraStreamSource(
            localizedName: "PedalHUD.Video",
            streamID: streamID,
            streamFormat: streamFormat,
            device: device
        )

        do {
            try device.addStream(streamSource.stream)
        } catch {
            fatalError("Failed to register the camera stream: \(error.localizedDescription)")
        }
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        [.deviceTransportType, .deviceModel]
    }

    func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
        let properties = CMIOExtensionDeviceProperties(dictionary: [:])
        properties.transportType = kIOAudioDeviceTransportTypeVirtual
        properties.model = "PedalHUD Synthetic Camera"
        return properties
    }

    func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {}

    func startStreaming() {
        guard streamTimer == nil else {
            return
        }

        let metricsReader = self.metricsReader
        let overlayConfigurationStore = self.overlayConfigurationStore
        let renderer = self.renderer
        let captureSource = self.captureSource
        let frameDuration = self.frameDuration

        guard let stream = self.streamSource.stream else {
            NSLog("PedalHUDCameraExtension failed to start streaming because the CMIO stream is missing.")
            return
        }

        guard let videoDescription else {
            NSLog("PedalHUDCameraExtension failed to start streaming because the video description is missing.")
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: streamingQueue)
        let streamEndpoint = StreamEndpoint(stream: stream)
        timer.schedule(deadline: .now(), repeating: .milliseconds(33))
        timer.setEventHandler {
            [metricsReader, overlayConfigurationStore, renderer, captureSource, streamEndpoint, videoDescription, frameDuration]
            in
            Self.emitFrame(
                metricsReader: metricsReader,
                configuration: overlayConfigurationStore.load(),
                renderer: renderer,
                captureSource: captureSource,
                stream: streamEndpoint,
                videoDescription: videoDescription,
                frameDuration: frameDuration
            )
        }
        streamTimer = timer
        timer.resume()

        // Avoid re-entering AVFoundation device discovery on the synchronous CMIO start callback.
        captureSource.startAsync()
    }

    func stopStreaming() {
        streamTimer?.cancel()
        streamTimer = nil
        captureSource.stop()
    }

    private static func emitFrame(
        metricsReader: PedalHUDMetricsReader,
        configuration: OverlayConfiguration,
        renderer: PedalHUDFrameRenderer,
        captureSource: PedalHUDCameraCaptureSource,
        stream: StreamEndpoint,
        videoDescription: CMFormatDescription,
        frameDuration: CMTime
    ) {
        let metrics = metricsReader.latestMetrics()
        let inputFrame = captureSource.currentFrame()

        guard let pixelBuffer = renderer.makeFrame(
            width: 1280,
            height: 720,
            metrics: metrics,
            configuration: configuration,
            inputPixelBuffer: inputFrame
        ) else {
            return
        }

        var timing = CMSampleTimingInfo(
            duration: frameDuration,
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: videoDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )

        if status == noErr, let sampleBuffer {
            stream.stream.send(
                sampleBuffer,
                discontinuity: [],
                hostTimeInNanoseconds: UInt64(timing.presentationTimeStamp.seconds * Double(NSEC_PER_SEC))
            )
        }
    }
}
