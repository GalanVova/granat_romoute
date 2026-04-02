import SwiftUI

struct ShellView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home",    systemImage: "house.fill") }
                .tag(0)
            NotificationsView()
                .tabItem { Label("Events",  systemImage: "bell.fill") }
                .tag(1)
            BalanceView()
                .tabItem { Label("Balance", systemImage: "creditcard.fill") }
                .tag(2)
            HelpView()
                .tabItem { Label("Help",    systemImage: "questionmark.circle.fill") }
                .tag(3)
        }
        .tint(Color.primaryRed)
        .navigationBarHidden(true)
    }
}

// MARK: - Balance

@MainActor
class BalanceViewModel: ObservableObject {
    @Published var balance: String = ""
    @Published var isLoading = false
    @Published var error: String?

    func load(session: Session?) async {
        guard let session else { return }
        isLoading = true
        error = nil
        do {
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let c = WampV1Client(uri: uri)
            try await c.connect()
            let a = LunAPI(client: c)
            _ = try await a.signupRaw(login: session.login, password: session.password)
            balance = try await a.getBalance()
            isLoading = false
            await c.close()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct BalanceView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = BalanceViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text("Error")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else {
                VStack(spacing: 16) {
                    Text("Balance")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(vm.balance.isEmpty ? "—" : vm.balance)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primaryRed)
                }
            }
        }
        .task { await vm.load(session: appState.session) }
    }
}

// MARK: - Help

@MainActor
class HelpViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isLoading = false
    @Published var error: String?

    func load(session: Session?) async {
        guard let session else { return }
        isLoading = true
        error = nil
        do {
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let c = WampV1Client(uri: uri)
            try await c.connect()
            let a = LunAPI(client: c)
            _ = try await a.signupRaw(login: session.login, password: session.password)
            text = try await a.getHelpText()
            isLoading = false
            await c.close()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct HelpView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HelpViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text("Error")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Help")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        Text(vm.text.isEmpty ? "No help information available." : vm.text)
                            .font(.system(size: 15))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(4)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .task { await vm.load(session: appState.session) }
    }
}

// MARK: - Notifications / Events

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var events: [PanelEvent] = []
    @Published var isLoading = false
    @Published var error: String?

    func load(session: Session?) async {
        guard let session else { return }
        isLoading = true
        error = nil
        do {
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let c = WampV1Client(uri: uri)
            try await c.connect()
            let a = LunAPI(client: c)
            _ = try await a.signupRaw(login: session.login, password: session.password)
            events = try await a.getEvents()
            isLoading = false
            await c.close()
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = NotificationsViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text("Error")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else if vm.events.isEmpty {
                Text("No events")
                    .foregroundColor(.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Events")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        ForEach(vm.events) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(.textPrimary)
                                HStack {
                                    if !event.panelId.isEmpty {
                                        Text("# \(event.panelId)/\(event.group)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Spacer()
                                    if !event.time.isEmpty {
                                        Text(event.time)
                                            .font(.system(size: 12))
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            Divider()
                                .background(Color.inputBorder)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .task { await vm.load(session: appState.session) }
    }
}
