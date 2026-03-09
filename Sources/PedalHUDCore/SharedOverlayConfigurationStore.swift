import Foundation

public struct SharedOverlayConfigurationStore {
    private let defaults: UserDefaults
    private let key = "pedalHUD.overlayConfiguration"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(appGroupIdentifier: String = PedalHUDIdentifiers.appGroup) {
        defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    public func load() -> OverlayConfiguration {
        guard let data = defaults.data(forKey: key),
              let configuration = try? decoder.decode(OverlayConfiguration.self, from: data) else {
            return .defaultConfiguration
        }

        return migrated(configuration)
    }

    public func save(_ configuration: OverlayConfiguration) {
        guard let data = try? encoder.encode(configuration) else {
            return
        }

        defaults.set(data, forKey: key)
    }

    private func migrated(_ configuration: OverlayConfiguration) -> OverlayConfiguration {
        guard configuration.placement == .topTrailing else {
            return configuration
        }

        var migratedConfiguration = configuration
        migratedConfiguration.placement = .bottomCenter

        if migratedConfiguration.cornerInset == 32 {
            migratedConfiguration.cornerInset = 20
        }

        if migratedConfiguration.panelOpacity == 0.84 {
            migratedConfiguration.panelOpacity = 0.9
        }

        return migratedConfiguration
    }
}
