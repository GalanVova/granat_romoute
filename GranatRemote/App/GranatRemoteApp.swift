import SwiftUI
import UserNotifications

@main
struct GranatRemoteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appState    = AppState()
    @StateObject private var appSettings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(appSettings)
                .preferredColorScheme(appSettings.theme.colorScheme)
                .onAppear {
                    // Don't prompt for permission on cold launch — only re-queue if already granted
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        guard settings.authorizationStatus == .authorized else { return }
                        BackgroundScheduleRunner.shared.scheduleNextIfNeeded()
                        let rules = ScheduleStore.shared.rules
                        if !rules.isEmpty {
                            ScheduleNotificationManager.shared.rescheduleAll(rules: rules)
                        }
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @State private var splashDone = false

    var body: some View {
        if !splashDone {
            SplashView(onDone: { splashDone = true })
                .onAppear {
                    AppDelegate.appState = appState
                    appState.logout()
                    // Priority 1: launch args
                    let args = ProcessInfo.processInfo.arguments
                    if let li = args.firstIndex(of: "-login"), li + 1 < args.count,
                       let pi = args.firstIndex(of: "-password"), pi + 1 < args.count {
                        let login = args[li + 1]
                        let pass  = args[pi + 1]
                        let pcn = demoPCNs.first!
                        appState.setPCN(pcn)
                        appState.setSession(Session(host: pcn.host, port: pcn.port, login: login, password: pass))
                    } else {
                        _ = appState.loadSavedCredentials()
                    }
                }
        } else if appState.session != nil {
            // Logged in — ShellView is root, completely separate from pre-login NavigationStack
            ShellView()
        } else {
            // Not logged in — pre-login flow in its own NavigationStack
            NavigationStack(path: $appState.path) {
                WelcomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .welcome:       WelcomeView()
                        case .countrySelect: CountrySelectView()
                        case .pcnSelect(let code):
                            let country = demoCountries.first { $0.code == code } ?? demoCountries[0]
                            PCNSelectView(country: country)
                        case .login:         LoginView()
                        case .recoverPassword: RecoverPasswordView()
                        case .shell:         EmptyView()
                        }
                    }
            }
            .id(appSettings.language.rawValue)
        }
    }
}
