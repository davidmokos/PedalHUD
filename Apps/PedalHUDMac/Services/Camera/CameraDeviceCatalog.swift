@preconcurrency import AVFoundation
import Foundation

struct CameraDeviceOption: Identifiable, Equatable, Sendable {
    let id: String
    let localizedName: String
}

enum CameraDeviceCatalog {
    static func availableCameras() -> [CameraDeviceOption] {
        discoverySession.devices
            .filter { device in
                !device.localizedName.localizedCaseInsensitiveContains("PedalHUD")
            }
            .map { device in
                CameraDeviceOption(
                    id: device.uniqueID,
                    localizedName: device.localizedName
                )
            }
    }

    static func device(for uniqueID: String?) -> AVCaptureDevice? {
        let devices = discoverySession.devices.filter { device in
            !device.localizedName.localizedCaseInsensitiveContains("PedalHUD")
        }

        if let uniqueID, let matchingDevice = devices.first(where: { $0.uniqueID == uniqueID }) {
            return matchingDevice
        }

        if let frontFacingDevice = devices.first(where: { $0.position == .front }) {
            return frontFacingDevice
        }

        return devices.first
    }

    private static var discoverySession: AVCaptureDevice.DiscoverySession {
        var preferredDeviceTypes: [AVCaptureDevice.DeviceType] = [
            .external,
            .builtInWideAngleCamera,
        ]

        if #available(macOS 14.0, *) {
            preferredDeviceTypes.insert(.continuityCamera, at: 1)
        }

        return AVCaptureDevice.DiscoverySession(
            deviceTypes: preferredDeviceTypes,
            mediaType: .video,
            position: .unspecified
        )
    }
}
