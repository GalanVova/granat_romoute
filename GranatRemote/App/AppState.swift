import SwiftUI

enum AppRoute: Hashable {
    case welcome
    case countrySelect
    case pcnSelect(String) // countryCode
    case login
    case shell
    case recoverPassword
}

@MainActor
final class AppState: ObservableObject {
    @Published var country: Country?
    @Published var pcn: PCN?
    @Published var session: Session?
    @Published var path = NavigationPath()

    /// Shared WAMP API — set by ShellViewModel after successful login
    @Published var api: LunAPI?

    func setCountry(_ c: Country) { country = c; pcn = nil }
    func setPCN(_ p: PCN)         { pcn = p }

    func setSession(_ s: Session?) { session = s }

    func logout() {
        session = nil
        country = nil
        pcn = nil
        api = nil
        path = NavigationPath()
    }

    func navigate(to route: AppRoute) { path.append(route) }
    func goBack() { if !path.isEmpty { path.removeLast() } }

    // MARK: - Persistent credentials
    private enum Keys {
        static let login = "saved_login"
        static let password = "saved_password"
        static let pcnId = "saved_pcn_id"
    }

    func saveCredentials() {
        guard let session, let pcn else { return }
        UserDefaults.standard.set(session.login, forKey: Keys.login)
        UserDefaults.standard.set(session.password, forKey: Keys.password)
        UserDefaults.standard.set(pcn.id, forKey: Keys.pcnId)
    }

    func loadSavedCredentials() -> Bool {
        guard let login = UserDefaults.standard.string(forKey: Keys.login),
              let password = UserDefaults.standard.string(forKey: Keys.password) else { return false }
        let pcnId = UserDefaults.standard.string(forKey: Keys.pcnId) ?? ""
        let foundPCN = demoPCNs.first { $0.id == pcnId } ?? demoPCNs.first!
        setPCN(foundPCN)
        setSession(Session(host: foundPCN.host, port: foundPCN.port, login: login, password: password))
        return true
    }

    func clearSavedCredentials() {
        UserDefaults.standard.removeObject(forKey: Keys.login)
        UserDefaults.standard.removeObject(forKey: Keys.password)
        UserDefaults.standard.removeObject(forKey: Keys.pcnId)
    }
}
