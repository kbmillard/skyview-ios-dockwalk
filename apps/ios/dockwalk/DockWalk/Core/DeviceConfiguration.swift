import Foundation

struct DeviceConfiguration: Equatable, Codable {
    var apiBaseURLString: String
    var orgId: String
    var facilityId: String
    var facilityName: String

    /// Railway production API (canonical URL — see service `ARCHITECT_RECAP.md`).
    static let railwayProductionAPIBaseURL = "https://dockwalk-api-production.up.railway.app"

    static let devDefaults = DeviceConfiguration(
        apiBaseURLString: "http://localhost:8790",
        orgId: "00000000-0000-4000-8000-000000000001",
        facilityId: "00000000-0000-4000-8000-000000000010",
        facilityName: "SkyPrairie Demo DC"
    )

    var apiBaseURL: URL? {
        URL(string: apiBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isValid: Bool {
        apiBaseURL != nil && !orgId.trimmingCharacters(in: .whitespaces).isEmpty
    }

    static func normalized(
        apiBaseURLString: String,
        orgId: String,
        facilityId: String,
        facilityName: String
    ) -> DeviceConfiguration {
        var urlString = apiBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }
        return DeviceConfiguration(
            apiBaseURLString: urlString,
            orgId: orgId.trimmingCharacters(in: .whitespacesAndNewlines),
            facilityId: facilityId.trimmingCharacters(in: .whitespacesAndNewlines),
            facilityName: facilityName.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
