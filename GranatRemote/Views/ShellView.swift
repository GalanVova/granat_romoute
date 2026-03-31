import SwiftUI

struct ShellView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home",    systemImage: "house.fill") }
                .tag(0)
            DarkPlaceholder(title: "Chat")
                .tabItem { Label("Chat",    systemImage: "bubble.left.fill") }
                .tag(1)
            DarkPlaceholder(title: "Balance")
                .tabItem { Label("Balance", systemImage: "creditcard.fill") }
                .tag(2)
            DarkPlaceholder(title: "Call")
                .tabItem { Label("Call",    systemImage: "phone.fill") }
                .tag(3)
        }
        .tint(Color.primaryRed)
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
    }
}

struct DarkPlaceholder: View {
    let title: String
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            Text("\(title) — coming soon")
                .foregroundColor(.textSecondary)
        }
    }
}
