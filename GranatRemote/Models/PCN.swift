import Foundation

struct PCN: Identifiable, Equatable {
    let id: String
    let countryCode: String
    let name: String
    let host: String
    let port: Int
}
