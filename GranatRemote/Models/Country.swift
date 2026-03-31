import Foundation

struct Country: Identifiable, Equatable {
    let id: String
    let code: String
    let name: String
    let flag: String

    init(code: String, name: String, flag: String = "") {
        self.id = code
        self.code = code
        self.name = name
        self.flag = flag
    }
}
