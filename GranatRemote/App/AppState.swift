import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var country: Country?
    @Published var pcn: PCN?
    @Published var session: Session?

    func setCountry(_ c: Country) {
        country = c
        pcn = nil
    }

    func setPCN(_ p: PCN) {
        pcn = p
    }

    func setSession(_ s: Session?) {
        session = s
    }

    func logout() {
        session = nil
        country = nil
        pcn = nil
    }
}
