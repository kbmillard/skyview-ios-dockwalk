import Foundation

enum DeviceConfigurationStore {
    private static let apiBaseURLKey = "DockWalk.apiBaseURL"
    private static let orgIdKey = "DockWalk.orgId"
    private static let facilityIdKey = "DockWalk.facilityId"
    private static let facilityNameKey = "DockWalk.facilityName"

    static func load(using defaults: UserDefaults = .standard) -> DeviceConfiguration {
        let dev = DeviceConfiguration.devDefaults
        guard defaults.string(forKey: apiBaseURLKey) != nil else {
            return dev
        }
        return DeviceConfiguration(
            apiBaseURLString: defaults.string(forKey: apiBaseURLKey) ?? dev.apiBaseURLString,
            orgId: defaults.string(forKey: orgIdKey) ?? dev.orgId,
            facilityId: defaults.string(forKey: facilityIdKey) ?? dev.facilityId,
            facilityName: defaults.string(forKey: facilityNameKey) ?? dev.facilityName
        )
    }

    static func save(_ configuration: DeviceConfiguration, using defaults: UserDefaults = .standard) {
        defaults.set(configuration.apiBaseURLString, forKey: apiBaseURLKey)
        defaults.set(configuration.orgId, forKey: orgIdKey)
        defaults.set(configuration.facilityId, forKey: facilityIdKey)
        defaults.set(configuration.facilityName, forKey: facilityNameKey)
    }

    static func resetToDevDefaults(using defaults: UserDefaults = .standard) -> DeviceConfiguration {
        let dev = DeviceConfiguration.devDefaults
        save(dev, using: defaults)
        return dev
    }

    static func clear(using defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: apiBaseURLKey)
        defaults.removeObject(forKey: orgIdKey)
        defaults.removeObject(forKey: facilityIdKey)
        defaults.removeObject(forKey: facilityNameKey)
    }
}
