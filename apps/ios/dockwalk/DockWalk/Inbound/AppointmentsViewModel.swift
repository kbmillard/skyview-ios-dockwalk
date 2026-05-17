import Foundation
import Observation

@Observable
final class AppointmentsViewModel {
    private(set) var appointments: [ReceivingAppointment] = []
    private(set) var isLoading = false
    private(set) var apiReachable = false

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient(baseURL: AppEnvironment.shared.apiBaseURL)) {
        self.apiClient = apiClient
        loadStubData()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        apiReachable = await apiClient.healthCheck()
        if !apiReachable {
            loadStubData()
        }
    }

    private func loadStubData() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        appointments = [
            ReceivingAppointment(
                id: "apt-001",
                carrier: "SwiftLine Freight",
                dock: "Dock 3",
                scheduledAt: calendar.date(byAdding: .hour, value: 8, to: base)!,
                status: .receiving,
                poNumber: "PO-88421",
                palletCount: 24
            ),
            ReceivingAppointment(
                id: "apt-002",
                carrier: "Midwest Carriers",
                dock: "Dock 1",
                scheduledAt: calendar.date(byAdding: .hour, value: 10, to: base)!,
                status: .scheduled,
                poNumber: "PO-88455",
                palletCount: 18
            ),
            ReceivingAppointment(
                id: "apt-003",
                carrier: "Blue Ridge 3PL",
                dock: "Door 12",
                scheduledAt: calendar.date(byAdding: .hour, value: 13, to: base)!,
                status: .checkedIn,
                poNumber: "PO-88501",
                palletCount: 12
            ),
            ReceivingAppointment(
                id: "apt-004",
                carrier: "National LTL",
                dock: "Dock 5",
                scheduledAt: calendar.date(byAdding: .hour, value: 15, to: base)!,
                status: .delayed,
                poNumber: "PO-88522",
                palletCount: 30
            ),
        ]
    }
}
