import CoreMediaIO
import Foundation

final class PedalHUDCameraStreamSource: NSObject, CMIOExtensionStreamSource {
    private(set) var stream: CMIOExtensionStream!
    let device: CMIOExtensionDevice

    private let streamFormat: CMIOExtensionStreamFormat
    private var activeFormatIndex = 0

    init(
        localizedName: String,
        streamID: UUID,
        streamFormat: CMIOExtensionStreamFormat,
        device: CMIOExtensionDevice
    ) {
        self.device = device
        self.streamFormat = streamFormat
        super.init()

        stream = CMIOExtensionStream(
            localizedName: localizedName,
            streamID: streamID,
            direction: .source,
            clockType: .hostTime,
            source: self
        )
    }

    var formats: [CMIOExtensionStreamFormat] {
        [streamFormat]
    }

    var availableProperties: Set<CMIOExtensionProperty> {
        [.streamActiveFormatIndex, .streamFrameDuration]
    }

    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let properties = CMIOExtensionStreamProperties(dictionary: [:])
        properties.activeFormatIndex = activeFormatIndex
        properties.frameDuration = streamFormat.minFrameDuration
        return properties
    }

    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            self.activeFormatIndex = activeFormatIndex
        }
    }

    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        true
    }

    func startStream() throws {
        guard let deviceSource = device.source as? PedalHUDCameraDeviceSource else {
            fatalError("Unexpected device source type: \(String(describing: device.source))")
        }

        deviceSource.startStreaming()
    }

    func stopStream() throws {
        guard let deviceSource = device.source as? PedalHUDCameraDeviceSource else {
            fatalError("Unexpected device source type: \(String(describing: device.source))")
        }

        deviceSource.stopStreaming()
    }
}

