import SwiftUI

@main
struct GranatRemoteApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var splashDone = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if !splashDone {
            SplashView(onDone: { splashDone = true })
                .onAppear {
                    appState.logout()
                    // Auto-login via launch args: -login <l> -password <p>
                    let args = ProcessInfo.processInfo.arguments
                    if let li = args.firstIndex(of: "-login"), li + 1 < args.count,
                       let pi = args.firstIndex(of: "-password"), pi + 1 < args.count {
                        let login = args[li + 1]
                        let pass  = args[pi + 1]
                        let pcn = demoPCNs.first!
                        appState.setPCN(pcn)
                        appState.setSession(Session(host: pcn.host, port: pcn.port, login: login, password: pass))
                    }
                }
        } else {
            NavigationStack(path: $appState.path) {
                WelcomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .welcome:
                            WelcomeView()
                        case .countrySelect:
                            CountrySelectView()
                        case .pcnSelect(let code):
                            let country = demoCountries.first { $0.code == code } ?? demoCountries[0]
                            PCNSelectView(country: country)
                        case .login:
                            LoginView()
                        case .recoverPassword:
                            RecoverPasswordView()
                        case .shell:
                            ShellView()
                        }
                    }
            }
        }
    }
}
