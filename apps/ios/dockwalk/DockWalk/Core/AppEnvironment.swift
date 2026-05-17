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
        facilityId: String = "00000000-0000-4000-8000-000000000010",
        facilityName: String = "SkyPrairie Demo DC",
        orgId: String = "00000000-0000-4000-8000-000000000001",
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
