import Foundation

struct IdentifiedString: Identifiable, Hashable {
    let id: String
    var value: String { id }
}
