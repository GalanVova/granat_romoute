import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var groups: [PanelGroup] = []
    @Published var isLoading = true
    @Published var error: String?

    private var api: LunAPI?

    func load(api: LunAPI?, session: Session?) async {
        guard let api else { error = "Not connected"; isLoading = false; return }
        self.api = api
        isLoading = true
        error = nil
        do {
            var g = try await api.getPanelGroups()
            if g.isEmpty, let session {
                if let signupRes = try? await api.signupRaw(login: session.login, password: session.password) {
                    g = api.parsePanelsFromSignup(signupRes)
                }
            }
            self.groups = g
            self.isLoading = false
            await loadStates(groups: g, api: api)
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

    func disconnect() { }
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
        .task { await vm.load(api: appState.api, session: appState.session) }
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
                Task { await vm.load(api: appState.api, session: appState.session) }
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

    private var armColor: Color {
        guard let state = group.state else { return .textSecondary }
        switch state.armMode {
        case 1: return .primaryRed
        case 2: return .orange
        default: return .selectedGreen
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Header row
                HStack {
                    Text("# \(group.panelId)/\(group.group)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }

                // Name
                Text(group.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Address
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

                Divider().background(Color.inputBorder)

                // Status row: icons + arm badge
                HStack(spacing: 0) {
                    statusIconsRow
                    Spacer()
                    armStatusBadge
                }
            }
            .padding(14)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIconsRow: some View {
        HStack(spacing: 12) {
            if let state = group.state {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(state.hasSignal ? .selectedGreen : .textSecondary)
                Image(systemName: "bolt")
                    .foregroundColor(state.hasMainPower ? .selectedGreen : .textSecondary)
                Image(systemName: "battery.100")
                    .foregroundColor(state.hasBattery ? .selectedGreen : .textSecondary)
                if state.hasWifi {
                    Image(systemName: "wifi").foregroundColor(.selectedGreen)
                }
                if state.hasCamera {
                    Image(systemName: "video").foregroundColor(.selectedGreen)
                }
            } else {
                Image(systemName: "antenna.radiowaves.left.and.right").foregroundColor(.textSecondary)
                Image(systemName: "bolt").foregroundColor(.textSecondary)
                Image(systemName: "battery.100").foregroundColor(.textSecondary)
            }
        }
        .font(.system(size: 14))
    }

    @ViewBuilder
    private var armStatusBadge: some View {
        if let state = group.state {
            HStack(spacing: 4) {
                Image(systemName: state.armMode == 1 ? "lock.fill" : (state.armMode == 2 ? "house.fill" : "lock.open.fill"))
                    .font(.system(size: 11, weight: .semibold))
                Text(state.armLabel)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(armColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(armColor.opacity(0.15))
            .cornerRadius(8)
        } else {
            ProgressView().scaleEffect(0.5).frame(width: 40)
        }
    }
}

// MARK: - Single group commands grid
struct SingleGroupView: View {
    let group: PanelGroup
    let onCommand: (Int, Int) -> Void
    let onBack: () -> Void

    private var armColor: Color {
        guard let state = group.state else { return .textSecondary }
        switch state.armMode {
        case 1: return .primaryRed
        case 2: return .orange
        default: return .selectedGreen
        }
    }

    let commands: [(String, String, Int)] = [
        ("house.fill",               "Arm stay\nat home",    55),
        ("lock.open.fill",           "Disarm",              53),
        ("lock.fill",                "Arm",                 52),
        ("sos",                      "SOS\nAlarm",          54),
        ("power",                    "Toggle\noutput",      43),
        ("arrow.up.right.square",    "Output\nstatus",      44),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
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
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("# \(group.panelId)/\(group.group)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
                Text(group.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                if let addr = group.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin").font(.system(size: 11)).foregroundColor(.textSecondary)
                        Text(addr).font(.system(size: 12)).foregroundColor(.textSecondary).lineLimit(1)
                    }
                }

                Divider().background(Color.inputBorder)

                // Status icons + arm badge
                HStack(spacing: 0) {
                    if let state = group.state {
                        HStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(state.hasSignal ? .selectedGreen : .textSecondary)
                            Image(systemName: "bolt")
                                .foregroundColor(state.hasMainPower ? .selectedGreen : .textSecondary)
                            Image(systemName: "battery.100")
                                .foregroundColor(state.hasBattery ? .selectedGreen : .textSecondary)
                            if state.hasWifi {
                                Image(systemName: "wifi").foregroundColor(.selectedGreen)
                            }
                            if state.hasCamera {
                                Image(systemName: "video").foregroundColor(.selectedGreen)
                            }
                        }
                        .font(.system(size: 15))
                    } else {
                        HStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Image(systemName: "bolt")
                            Image(systemName: "battery.100")
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                    }

                    Spacer()

                    // Arm status badge
                    if let state = group.state {
                        HStack(spacing: 5) {
                            Image(systemName: state.armMode == 1 ? "lock.fill" : (state.armMode == 2 ? "house.fill" : "lock.open.fill"))
                                .font(.system(size: 12, weight: .semibold))
                            Text(state.armLabel)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(armColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(armColor.opacity(0.15))
                        .cornerRadius(8)
                    } else {
                        ProgressView().scaleEffect(0.6).frame(width: 50)
                    }
                }
            }
            .padding(14)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 16)

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
                .padding(.top, 16)
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
