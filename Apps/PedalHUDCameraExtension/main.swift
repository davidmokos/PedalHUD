import CoreMediaIO
import Foundation

let providerSource = PedalHUDCameraProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()

