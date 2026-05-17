import Foundation
import Observation

@Observable
final class AppEnvironment {
    static let shared = AppEnvironment()

    private(set) var configRevision = 0

    var apiBaseURL: URL
    var facilityId: String
    var facilityName: String
    var orgId: String
    var userRole: UserRole

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = DeviceConfigurationStore.load(using: defaults)
        self.apiBaseURL = stored.apiBaseURL ?? DeviceConfiguration.devDefaults.apiBaseURL!
        self.facilityId = stored.facilityId
        self.facilityName = stored.facilityName
        self.orgId = stored.orgId
        self.userRole = .receiver
    }

    func makeAPIClient() -> APIClient {
        APIClient(baseURL: apiBaseURL)
    }

    @discardableResult
    func apply(
        apiBaseURLString: String,
        orgId: String,
        facilityId: String,
        facilityName: String = "SkyPrairie Demo DC"
    ) -> String? {
        let config = DeviceConfiguration.normalized(
            apiBaseURLString: apiBaseURLString,
            orgId: orgId,
            facilityId: facilityId,
            facilityName: facilityName
        )
        guard let url = config.apiBaseURL else {
            return "Enter a valid API base URL (e.g. http://localhost:8790)."
        }
        apiBaseURL = url
        self.orgId = config.orgId
        self.facilityId = config.facilityId
        self.facilityName = config.facilityName
        DeviceConfigurationStore.save(config, using: defaults)
        configRevision += 1
        return nil
    }

    func resetToDevDefaults() {
        let dev = DeviceConfigurationStore.resetToDevDefaults(using: defaults)
        apiBaseURL = dev.apiBaseURL!
        orgId = dev.orgId
        facilityId = dev.facilityId
        facilityName = dev.facilityName
        configRevision += 1
    }

    var currentConfiguration: DeviceConfiguration {
        DeviceConfiguration(
            apiBaseURLString: apiBaseURL.absoluteString,
            orgId: orgId,
            facilityId: facilityId,
            facilityName: facilityName
        )
    }
}

enum UserRole: String, CaseIterable, Codable {
    case receiver, picker, loader, supervisor

    var displayName: String {
        switch self {
        case .receiver: return "Receiver"
        case .picker: return "Picker"
        case .loader: return "Loader"
        case .supervisor: return "Supervisor"
        }
    }
}
