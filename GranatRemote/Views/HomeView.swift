import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var groups: [PanelGroup] = []
    @Published var isLoading = true
    @Published var error: String?

    private var client: WampV1Client?
    private var api: LunAPI?

    func load(session: Session?) async {
        guard let session, !session.host.isEmpty else {
            isLoading = false
            error = "No active session."
            return
        }
        isLoading = true
        error = nil
        do {
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let c = WampV1Client(uri: uri)
            try await c.connect()
            let a = LunAPI(client: c)
            let signupRes = try await a.signupRaw(login: session.login, password: session.password)
            var g = a.parsePanelsFromSignup(signupRes)
            if g.isEmpty {
                g = try await a.getPanelGroups()
            }
            session.groups = g
            self.client = c
            self.api = a
            self.groups = g
            self.isLoading = false
            // Load real state for each group
            await loadStates(groups: g, api: a)
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }

    private func loadStates(groups: [PanelGroup], api: LunAPI) async {
        var updated = groups
        for i in updated.indices {
            if let state = try? await api.getPanelState(panel: updated[i].panelId, group: updated[i].group) {
                updated[i].state = state
            }
        }
        self.groups = updated
    }

    func sendCommand(group: PanelGroup, cmd: Int, num: Int = 0) async {
        guard let api else { return }
        do {
            try await api.remoteControl(cmd: cmd, panel: group.panelId, group: group.group, num: num)
        } catch {
            self.error = "Command error: \(error.localizedDescription)"
        }
    }

    func disconnect() { Task { await client?.close() } }
}

// MARK: - Shell / Home entry point
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HomeViewModel()
    @State private var selectedGroup: PanelGroup?
    @State private var showOutputSheet = false
    @State private var pendingCmd: (PanelGroup, Int)?
    @State private var outputNumText = "1"

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                errorView(err)
            } else if let group = selectedGroup {
                SingleGroupView(group: group) { cmd, num in
                    if cmd == 43 || cmd == 44 {
                        pendingCmd = (group, cmd)
                        outputNumText = "1"
                        showOutputSheet = true
                    } else {
                        Task { await vm.sendCommand(group: group, cmd: cmd) }
                    }
                } onBack: {
                    selectedGroup = nil
                }
            } else {
                multiGroupView
            }
        }
        .task {
            await vm.load(session: appState.session)
        }
        .onDisappear { vm.disconnect() }
        .sheet(isPresented: $showOutputSheet) {
            OutputNumberSheet(text: $outputNumText) { num in
                if let (group, cmd) = pendingCmd {
                    Task { await vm.sendCommand(group: group, cmd: cmd, num: num) }
                }
                showOutputSheet = false
            } onCancel: { showOutputSheet = false }
        }
    }

    private var multiGroupView: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 20))
                    .foregroundColor(.textPrimary)
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(.textPrimary)
                    Circle()
                        .fill(Color.primaryRed)
                        .frame(width: 8, height: 8)
                        .offset(x: 2, y: -2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // PCN selector strip
            if let pcn = appState.pcn {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        PCNChip(name: pcn.name, selected: true)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }

            HStack {
                Text("Your objects")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(vm.groups) { group in
                        PanelGroupCard(group: group) {
                            selectedGroup = group
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }

    private func errorView(_ err: String) -> some View {
        VStack(spacing: 16) {
            Text("Connection error")
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text(err)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try again") {
                guard let sess = appState.session else { return }
                Task { await vm.load(session: sess) }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color.buttonDark)
            .foregroundColor(.textPrimary)
            .cornerRadius(8)
        }
        .padding(24)
    }
}

// MARK: - PCN chip
struct PCNChip: View {
    let name: String
    let selected: Bool
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.inputBackground)
                    .frame(width: 28, height: 28)
                Image(systemName: "s.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
            Text(name)
                .font(.system(size: 13))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}

// MARK: - Panel group card (list view)
struct PanelGroupCard: View {
    let group: PanelGroup
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("# \(group.panelId)/\(group.group)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundColor(.textSecondary)
                }
                Text(group.name)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                if let addr = group.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 11))
                            .foregroundColor(.textSecondary)
                        Text(addr)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }
                // Status icons — real state
                statusIconsRow

                Image(systemName: "chevron.down.circle")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding(14)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }

    @ViewBuilder
    private var statusIconsRow: some View {
        if let state = group.state {
            HStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(state.hasSignal ? .selectedGreen : .textSecondary)
                Image(systemName: "battery.100")
                    .foregroundColor(state.hasBattery ? .selectedGreen : .textSecondary)
                Image(systemName: "bolt")
                    .foregroundColor(state.hasMainPower ? .selectedGreen : .textSecondary)
                if state.hasCamera {
                    Image(systemName: "video")
                        .foregroundColor(.selectedGreen)
                }
                Image(systemName: "wifi")
                    .foregroundColor(state.hasWifi ? .selectedGreen : .textSecondary)
            }
            .font(.system(size: 13))
        } else {
            HStack(spacing: 10) {
                ForEach(["antenna.radiowaves.left.and.right", "battery.100", "bolt", "wifi"], id: \.self) { icon in
                    Image(systemName: icon).foregroundColor(.textSecondary)
                }
            }
            .font(.system(size: 13))
        }
    }
}

// MARK: - Single group commands grid
struct SingleGroupView: View {
    let group: PanelGroup
    let onCommand: (Int, Int) -> Void
    let onBack: () -> Void

    let commands: [(String, String, Int)] = [
        ("house",                    "Arm stay\nat home",    55),
        ("lock.open",                "Disarm",              53),
        ("lock",                     "Arm",                 52),
        ("sos",                      "SOS\nAlarm Button",   54),
        ("power",                    "Turn on/off\nexit",   43),
        ("arrow.up.right.square",    "Request\noutput st.", 44),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Nav
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundColor(.textPrimary)
                    Circle().fill(Color.primaryRed).frame(width: 8, height: 8).offset(x: 2, y: -2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Info card
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("# \(group.panelId)/\(group.group)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "ellipsis").foregroundColor(.textSecondary)
                }
                Text(group.name)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                if let addr = group.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin").font(.system(size: 11)).foregroundColor(.textSecondary)
                        Text(addr).font(.system(size: 12)).foregroundColor(.textSecondary).lineLimit(1)
                    }
                }
                // Real status icons
                if let state = group.state {
                    HStack(spacing: 10) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(state.hasSignal ? .selectedGreen : .textSecondary)
                        Image(systemName: "battery.100")
                            .foregroundColor(state.hasBattery ? .selectedGreen : .textSecondary)
                        Image(systemName: "bolt")
                            .foregroundColor(state.hasMainPower ? .selectedGreen : .textSecondary)
                        if state.hasCamera {
                            Image(systemName: "video").foregroundColor(.selectedGreen)
                        }
                        Image(systemName: "wifi")
                            .foregroundColor(state.hasWifi ? .selectedGreen : .textSecondary)
                    }
                    .font(.system(size: 13))
                } else {
                    HStack(spacing: 10) {
                        ForEach(["antenna.radiowaves.left.and.right", "battery.100", "bolt", "wifi"], id: \.self) { icon in
                            Image(systemName: icon).foregroundColor(.textSecondary)
                        }
                    }
                    .font(.system(size: 13))
                }

                // Real arm status
                HStack(spacing: 6) {
                    Text("Object status")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                    if let state = group.state {
                        let armColor: Color = state.armMode == 0 ? .selectedGreen : (state.armMode == 1 ? .primaryRed : .orange)
                        Image(systemName: state.isArmed ? "lock" : "lock.open")
                            .font(.system(size: 12))
                            .foregroundColor(armColor)
                        Text(state.armLabel)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(armColor)
                    } else {
                        ProgressView().scaleEffect(0.6)
                    }
                }
                .padding(.top, 2)
            }
            .padding(14)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)

            // Page dots
            HStack(spacing: 6) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(i == 1 ? Color.textPrimary : Color.inputBorder)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.vertical, 12)

            // Commands grid
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(commands, id: \.2) { (icon, label, cmd) in
                        CommandGridButton(icon: icon, label: label) {
                            onCommand(cmd, 0)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct CommandGridButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 90, alignment: .leading)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Output number sheet
struct OutputNumberSheet: View {
    @Binding var text: String
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Form {
                    Section("Output number") {
                        TextField("Number", text: $text)
                            .keyboardType(.numberPad)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .navigationTitle("Output number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel).foregroundColor(.primaryRed)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { onConfirm(Int(text) ?? 1) }.foregroundColor(.primaryRed)
                }
            }
        }
        .presentationDetents([.height(180)])
    }
}
