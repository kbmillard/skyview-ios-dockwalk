import Foundation

struct DeviceConfiguration: Equatable, Codable {
    var apiBaseURLString: String
    var orgId: String
    var facilityId: String
    var facilityName: String

    static let localDevAPIBaseURL = "http://localhost:8790"

    /// Railway production API (canonical URL — see service `ARCHITECT_RECAP.md`).
    static let railwayProductionAPIBaseURL = "https://dockwalk-api-production.up.railway.app"

    private static let devOrgId = "00000000-0000-4000-8000-000000000001"
    private static let devFacilityId = "00000000-0000-4000-8000-000000000010"

    /// Default for new installs — Railway QA API.
    static let railwayQADefaults = DeviceConfiguration(
        apiBaseURLString: railwayProductionAPIBaseURL,
        orgId: devOrgId,
        facilityId: devFacilityId,
        facilityName: "SkyPrairie Demo DC"
    )

    /// Local DockWalk API on the Mac (Simulator).
    static let localDevDefaults = DeviceConfiguration(
        apiBaseURLString: localDevAPIBaseURL,
        orgId: devOrgId,
        facilityId: devFacilityId,
        facilityName: "SkyPrairie Demo DC"
    )

    /// Backward-compatible name — same as Railway QA defaults.
    static var devDefaults: DeviceConfiguration { railwayQADefaults }

    var apiBaseURL: URL? {
        URL(string: apiBaseURLString.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isValid: Bool {
        apiBaseURL != nil && !orgId.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isRailwayProduction: Bool {
        apiBaseURLString.contains("dockwalk-api-production.up.railway.app")
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
