import SwiftUI

@main
struct GranatRemoteApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
    }
}
