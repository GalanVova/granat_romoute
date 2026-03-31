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

    var body: some View {
        if !splashDone {
            SplashView(onDone: { splashDone = true })
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
