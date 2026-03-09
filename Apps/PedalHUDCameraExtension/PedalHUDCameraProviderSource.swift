import CoreMediaIO
import Foundation

final class PedalHUDCameraProviderSource: NSObject, CMIOExtensionProviderSource {
    private(set) var provider: CMIOExtensionProvider!
    private let deviceSource: PedalHUDCameraDeviceSource

    init(clientQueue: DispatchQueue?) {
        deviceSource = PedalHUDCameraDeviceSource(localizedName: "PedalHUD Camera")
        super.init()

        provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)

        do {
            try provider.addDevice(deviceSource.device)
        } catch {
            fatalError("Failed to register the virtual camera device: \(error.localizedDescription)")
        }
    }

    func connect(to client: CMIOExtensionClient) throws {}

    func disconnect(from client: CMIOExtensionClient) {}

    var availableProperties: Set<CMIOExtensionProperty> {
        [.providerManufacturer]
    }

    func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
        let properties = CMIOExtensionProviderProperties(dictionary: [:])
        properties.manufacturer = "PedalHUD"
        return properties
    }

    func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {}
}

