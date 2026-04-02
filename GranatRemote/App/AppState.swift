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
}
