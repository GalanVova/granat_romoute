import SwiftUI

// MARK: - Shell connection VM

@MainActor
class ShellViewModel: ObservableObject {
    private var client: WampV1Client?

    func connect(session: Session?) async -> LunAPI? {
        guard let session else { return nil }
        do {
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let c = WampV1Client(uri: uri)
            try await c.connect()
            let a = LunAPI(client: c)
            _ = try await a.signupRaw(login: session.login, password: session.password)
            self.client = c
            return a
        } catch {
            return nil
        }
    }

    func disconnect() { Task { await client?.close() }; client = nil }
}

struct ShellView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var shellVM = ShellViewModel()
    @State private var selectedTab: Int = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count {
            return Int(args[i + 1]) ?? 0
        }
        return 0
    }()

    private func s(_ key: String) -> String { appSettings.t(key) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if let api = appState.api {
                TabView(selection: $selectedTab) {
                    NavigationStack {
                        HomeView()
                    }
                    .tabItem { Label(s("tab.home"),     systemImage: "house.fill") }
                    .tag(0)

                    NavigationStack {
                        NotificationsView()
                    }
                    .tabItem { Label(s("tab.events"),   systemImage: "bell.fill") }
                    .tag(1)

                    NavigationStack {
                        BalanceView()
                    }
                    .tabItem { Label(s("tab.balance"),  systemImage: "creditcard.fill") }
                    .tag(2)

                    NavigationStack {
                        HelpView()
                    }
                    .tabItem { Label(s("tab.help"),     systemImage: "questionmark.circle.fill") }
                    .tag(3)

                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem { Label(s("tab.settings"), systemImage: "gearshape.fill") }
                    .tag(4)
                }
                .tint(Color.primaryRed)
                .id(ObjectIdentifier(api))
            } else {
                ProgressView().tint(.textSecondary)
            }
        }
        .navigationBarHidden(true)
        .task {
            if appState.api == nil {
                appState.api = await shellVM.connect(session: appState.session)
            }
        }
        .onDisappear { shellVM.disconnect() }
    }
}

// MARK: - Balance

@MainActor
class BalanceViewModel: ObservableObject {
    @Published var balance: String = ""
    @Published var isLoading = false
    @Published var error: String?

    func load(api: LunAPI?) async {
        guard let api else { error = "Not connected"; return }
        isLoading = true
        error = nil
        do {
            balance = try await api.getBalance()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct BalanceView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var vm = BalanceViewModel()
    private func s(_ k: String) -> String { appSettings.t(k) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text(s("err.error"))
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
                        Text(s("balance.title"))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        let lines = vm.balance.isEmpty ? ["—"] : vm.balance.components(separatedBy: "\n")
                        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                            HStack {
                                let parts = line.components(separatedBy: " (")
                                VStack(alignment: .leading, spacing: 4) {
                                    if parts.count == 2 {
                                        let cn = parts[1].replacingOccurrences(of: ")", with: "")
                                        Text("Contract \(cn)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.textSecondary)
                                        Text(parts[0])
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.textPrimary)
                                    } else {
                                        Text(line)
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 10)
                        }
                    }
                }
            }
        }
        .task { await vm.load(api: appState.api) }
    }
}

// MARK: - Help

@MainActor
class HelpViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var isLoading = false
    @Published var error: String?

    func load(api: LunAPI?) async {
        guard let api else { error = "Not connected"; return }
        isLoading = true
        error = nil
        do {
            text = try await api.getHelpText()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct HelpView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var vm = HelpViewModel()
    private func s(_ k: String) -> String { appSettings.t(k) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text(s("err.error"))
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
                        Text(s("help.title"))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)
                        Text(vm.text.isEmpty ? s("help.none") : vm.text)
                            .font(.system(size: 15))
                            .foregroundColor(.textPrimary)
                            .lineSpacing(4)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .task { await vm.load(api: appState.api) }
    }
}

// MARK: - Notifications / Events

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var events: [PanelEvent] = []
    @Published var isLoading = false
    @Published var error: String?

    func load(api: LunAPI?) async {
        guard let api else { error = "Not connected"; return }
        isLoading = true
        error = nil
        do {
            events = try await api.getEvents()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var vm = NotificationsViewModel()
    private func s(_ k: String) -> String { appSettings.t(k) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text(s("err.error"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            } else if vm.events.isEmpty {
                Text(s("events.none"))
                    .foregroundColor(.textSecondary)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text(s("events.title"))
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
        .task { await vm.load(api: appState.api) }
    }
}
