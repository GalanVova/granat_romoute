import SwiftUI

struct ShellView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)

            PlaceholderView(title: "Chat")
                .tabItem {
                    Label("Chat", systemImage: "bubble.left")
                }
                .tag(1)

            PlaceholderView(title: "Balance")
                .tabItem {
                    Label("Balance", systemImage: "creditcard")
                }
                .tag(2)

            PlaceholderView(title: "Call")
                .tabItem {
                    Label("Call", systemImage: "phone")
                }
                .tag(3)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Logout") {
                    appState.logout()
                }
                .foregroundColor(Color(hex: "B5161B"))
            }
        }
    }
}

struct PlaceholderView: View {
    let title: String

    var body: some View {
        Text("\(title) (coming soon)")
            .font(.title3.weight(.semibold))
            .foregroundColor(.secondary)
    }
}
