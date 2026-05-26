import Foundation
import Observation

/// Facility-specific runtime config from API (staging code, valid bins).
@Observable
final class FacilityConfigStore {
    static let shared = FacilityConfigStore()

    private(set) var stagingLocationCode: String = ""
    private(set) var validLocationCodes: Set<String> = []
    private(set) var locationsSyncPhase: LocationsSyncPhase = .idle
    private(set) var revision = 0

    private var configLoaded = false

    func refresh(environment: AppEnvironment) async {
        let client = environment.makeAPIClient()
        let facilityId = environment.facilityId

        do {
            let config: FacilityConfigResponse = try await client.fetchFacilityConfig(facilityId: facilityId)
            stagingLocationCode = config.receive?.defaultStagingLocationCode?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            configLoaded = true
        } catch {
            if !configLoaded { stagingLocationCode = "" }
        }

        await refreshLocations(environment: environment)
        bumpRevision()
    }

    func refreshLocations(environment: AppEnvironment) async {
        locationsSyncPhase = .syncing
        let client = environment.makeAPIClient()
        let facilityId = environment.facilityId
        var codes: Set<String> = []
        var offset = 0
        let pageSize = 500

        do {
            while true {
                let page: FacilityLocationsResponse = try await client.fetchFacilityLocations(
                    facilityId: facilityId,
                    limit: pageSize,
                    offset: offset
                )
                for item in page.items {
                    let code = item.code.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !code.isEmpty { codes.insert(code) }
                }
                let total = page.pagination?.total ?? page.items.count
                offset += page.items.count
                if page.items.isEmpty || offset >= total { break }
            }
            validLocationCodes = codes
            locationsSyncPhase = .ready
        } catch {
            locationsSyncPhase = codes.isEmpty ? .failed(error.localizedDescription) : .ready
            if !codes.isEmpty { validLocationCodes = codes }
        }
    }

    func isValidLocation(_ code: String, environment: AppEnvironment) async -> LocationValidationResult {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid }

        if case .syncing = locationsSyncPhase {
            return .syncing
        }

        if validLocationCodes.contains(where: { $0.compare(trimmed, options: .caseInsensitive) == .orderedSame }) {
            return .valid
        }

        do {
            let lookup = try await environment.makeAPIClient().fetchFacilityLocation(
                facilityId: environment.facilityId,
                code: trimmed
            )
            if lookup.valid != false {
                validLocationCodes.insert(trimmed)
                return .valid
            }
        } catch {
            if let api = error as? APIClientError, case .httpStatus(404, _) = api {
                return .invalid
            }
        }

        return validLocationCodes.isEmpty ? .syncing : .invalid
    }

    func defaultReceiveLocation() -> String {
        stagingLocationCode
    }

    private func bumpRevision() {
        revision &+= 1
    }
}

enum LocationValidationResult: Equatable {
    case valid
    case invalid
    case syncing
}
