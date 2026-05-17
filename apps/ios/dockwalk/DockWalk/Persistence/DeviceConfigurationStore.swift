import Foundation

enum DeviceConfigurationStore {
    private static let apiBaseURLKey = "DockWalk.apiBaseURL"
    private static let orgIdKey = "DockWalk.orgId"
    private static let facilityIdKey = "DockWalk.facilityId"
    private static let facilityNameKey = "DockWalk.facilityName"

    static func load(using defaults: UserDefaults = .standard) -> DeviceConfiguration {
        let fallback = DeviceConfiguration.railwayQADefaults
        guard defaults.string(forKey: apiBaseURLKey) != nil else {
            return fallback
        }
        return DeviceConfiguration(
            apiBaseURLString: defaults.string(forKey: apiBaseURLKey) ?? fallback.apiBaseURLString,
            orgId: defaults.string(forKey: orgIdKey) ?? fallback.orgId,
            facilityId: defaults.string(forKey: facilityIdKey) ?? fallback.facilityId,
            facilityName: defaults.string(forKey: facilityNameKey) ?? fallback.facilityName
        )
    }

    static func save(_ configuration: DeviceConfiguration, using defaults: UserDefaults = .standard) {
        defaults.set(configuration.apiBaseURLString, forKey: apiBaseURLKey)
        defaults.set(configuration.orgId, forKey: orgIdKey)
        defaults.set(configuration.facilityId, forKey: facilityIdKey)
        defaults.set(configuration.facilityName, forKey: facilityNameKey)
    }

    static func resetToRailwayQADefaults(using defaults: UserDefaults = .standard) -> DeviceConfiguration {
        let qa = DeviceConfiguration.railwayQADefaults
        save(qa, using: defaults)
        return qa
    }

    static func resetToLocalDevDefaults(using defaults: UserDefaults = .standard) -> DeviceConfiguration {
        let local = DeviceConfiguration.localDevDefaults
        save(local, using: defaults)
        return local
    }

    /// Alias — resets to Railway QA (not localhost).
    static func resetToDevDefaults(using defaults: UserDefaults = .standard) -> DeviceConfiguration {
        resetToRailwayQADefaults(using: defaults)
    }

    static func clear(using defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: apiBaseURLKey)
        defaults.removeObject(forKey: orgIdKey)
        defaults.removeObject(forKey: facilityIdKey)
        defaults.removeObject(forKey: facilityNameKey)
    }
}
