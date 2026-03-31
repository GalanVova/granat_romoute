import Foundation

struct Country: Identifiable, Equatable {
    let id: String
    let code: String
    let name: String

    init(code: String, name: String) {
        self.id = code
        self.code = code
        self.name = name
    }
}
