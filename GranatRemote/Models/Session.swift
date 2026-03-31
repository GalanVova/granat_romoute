import Foundation

class Session {
    let host: String
    let port: Int
    let login: String
    let password: String
    var groups: [PanelGroup] = []

    init(host: String, port: Int, login: String, password: String) {
        self.host = host
        self.port = port
        self.login = login
        self.password = password
    }
}
