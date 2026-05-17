import Foundation
import Observation

@Observable
final class AppEnvironment {
    static let shared = AppEnvironment()

    var apiBaseURL: URL
    var facilityId: String
    var facilityName: String
    var orgId: String
    var userRole: UserRole

    init(
        apiBaseURL: URL = URL(string: "http://localhost:8790")!,
        facilityId: String = "facility-demo-01",
        facilityName: String = "SkyPrairie Demo DC",
        orgId: String = "org-demo-01",
        userRole: UserRole = .receiver
    ) {
        self.apiBaseURL = apiBaseURL
        self.facilityId = facilityId
        self.facilityName = facilityName
        self.orgId = orgId
        self.userRole = userRole
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
