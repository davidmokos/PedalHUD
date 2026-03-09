import Foundation
import SystemExtensions

@MainActor
final class CameraExtensionInstaller: NSObject {
    var onStatusChange: ((String) -> Void)?

    private var continuation: CheckedContinuation<String, Error>?

    func install() async throws -> String {
        let applicationPath = Bundle.main.bundleURL.resolvingSymlinksInPath().path

        guard applicationPath.hasPrefix("/Applications/") else {
            throw NSError(
                domain: "PedalHUDMac.CameraExtensionInstaller",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "System extensions can only be activated from /Applications. Copy the built app there, launch it, then activate the virtual camera again."
                ]
            )
        }

        let bundleIdentifier = try embeddedExtensionBundleIdentifier()
        onStatusChange?("Submitting virtual camera activation request...")

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let request = OSSystemExtensionRequest.activationRequest(
                forExtensionWithIdentifier: bundleIdentifier,
                queue: .main
            )
            request.delegate = self
            OSSystemExtensionManager.shared.submitRequest(request)
        }
    }

    private func embeddedExtensionBundleIdentifier() throws -> String {
        let fileManager = FileManager.default
        let extensionsDirectory = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("SystemExtensions", isDirectory: true)

        guard fileManager.fileExists(atPath: extensionsDirectory.path) else {
            throw NSError(
                domain: "PedalHUDMac.CameraExtensionInstaller",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "The app bundle does not contain an embedded virtual camera extension."
                ]
            )
        }

        let extensionURLs = try fileManager.contentsOfDirectory(
            at: extensionsDirectory,
            includingPropertiesForKeys: nil
        )

        guard let extensionURL = extensionURLs.first(where: { $0.pathExtension == "systemextension" }) else {
            throw NSError(
                domain: "PedalHUDMac.CameraExtensionInstaller",
                code: 3,
                userInfo: [
                    NSLocalizedDescriptionKey: "No embedded system extension was found in the app bundle."
                ]
            )
        }

        guard let bundleIdentifier = Bundle(url: extensionURL)?.bundleIdentifier else {
            throw NSError(
                domain: "PedalHUDMac.CameraExtensionInstaller",
                code: 4,
                userInfo: [
                    NSLocalizedDescriptionKey: "The embedded virtual camera extension is missing a bundle identifier."
                ]
            )
        }

        return bundleIdentifier
    }

    private func resolve(_ result: Result<String, Error>) {
        guard let continuation else {
            return
        }

        self.continuation = nil

        switch result {
        case .success(let message):
            continuation.resume(returning: message)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

extension CameraExtensionInstaller: @preconcurrency OSSystemExtensionRequestDelegate {
    func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
        onStatusChange?("Approve the virtual camera in System Settings > Privacy & Security. The request will finish after approval.")
    }

    func request(_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {
        switch result {
        case .completed:
            resolve(.success("Virtual camera activation finished. Reopen Photo Booth, Zoom, Meet, or Slack and look for PedalHUD Camera."))
        case .willCompleteAfterReboot:
            resolve(.success("Virtual camera activation is staged and will complete after a reboot. Restart the Mac, then reopen your video app."))
        @unknown default:
            resolve(.success("Virtual camera activation finished. Reopen your video app and check for PedalHUD Camera."))
        }
    }

    func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
        resolve(.failure(error))
    }

    func request(
        _ request: OSSystemExtensionRequest,
        actionForReplacingExtension existing: OSSystemExtensionProperties,
        withExtension ext: OSSystemExtensionProperties
    ) -> OSSystemExtensionRequest.ReplacementAction {
        .replace
    }
}
