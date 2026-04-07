import SwiftUI
import UserNotifications

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
            if let idx = groups.firstIndex(where: { $0.id == group.id }) {
                if let newState = try? await api.getPanelState(panel: group.panelId, group: group.group) {
                    groups[idx].state = newState
                }
            }
            sendCommandNotification(cmd: cmd, groupName: group.name)
        } catch {
            self.error = "Command error: \(error.localizedDescription)"
        }
    }

    private func sendCommandNotification(cmd: Int, groupName: String) {
        let (title, icon): (String, String)
        switch cmd {
        case 52: (title, icon) = ("Armed",        "🔒")
        case 53: (title, icon) = ("Disarmed",     "🔓")
        case 55: (title, icon) = ("Arm stay",     "🏠")
        case 54: (title, icon) = ("SOS Alarm",    "🚨")
        default: return   // no notification for output commands
        }

        let content = UNMutableNotificationContent()
        content.title = "\(icon) GRANAT — \(title)"
        content.body  = groupName
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "cmd_\(cmd)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil   // deliver immediately
        )
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func disconnect() { }
}

// MARK: - Home entry point

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var vm = HomeViewModel()
    @State private var selectedGroup: PanelGroup?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            if vm.isLoading {
                ProgressView().tint(.textSecondary)
            } else if let err = vm.error {
                errorView(err)
            } else if let group = selectedGroup {
                SingleGroupView(
                    group: group,
                    settings: appSettings,
                    vm: vm
                ) { selectedGroup = nil }
            } else {
                multiGroupView
            }
        }
        .task { await vm.load(api: appState.api, session: appState.session) }
        .onDisappear { vm.disconnect() }
    }

    private var multiGroupView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 20))
                    .foregroundColor(.textPrimary)
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

            if let pcn = appState.pcn {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) { PCNChip(name: pcn.name, selected: true) }
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }

            HStack {
                Text(appSettings.t("home.objects"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(vm.groups) { group in
                        PanelGroupCard(group: group, settings: appSettings) {
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
            Text(appSettings.t("home.connection_error"))
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text(err)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
            Button(appSettings.t("home.retry")) {
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
                Circle().fill(Color.inputBackground).frame(width: 28, height: 28)
                Image(systemName: "s.circle.fill").font(.system(size: 16)).foregroundColor(.textSecondary)
            }
            Text(name).font(.system(size: 13)).foregroundColor(.textPrimary).lineLimit(1)
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
    let settings: AppSettings
    let onTap: () -> Void

    private func s(_ k: String) -> String { settings.t(k) }

    private var armColor: Color {
        guard let state = group.state else { return .textSecondary }
        switch state.armMode {
        case 1: return .primaryRed
        case 2: return .orange
        default: return .selectedGreen
        }
    }

    private func armLabel(_ mode: Int) -> String {
        switch mode {
        case 0: return s("arm.disarmed")
        case 1: return s("arm.armed")
        case 2: return s("arm.home")
        default: return s("arm.unknown")
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("# \(group.panelId)/\(group.group)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                Text(group.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let addr = group.address {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin").font(.system(size: 11)).foregroundColor(.textSecondary)
                        Text(addr).font(.system(size: 12)).foregroundColor(.textSecondary).lineLimit(1)
                    }
                }
                Divider().background(Color.inputBorder)
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
                if state.hasWifi { Image(systemName: "wifi").foregroundColor(.selectedGreen) }
                if state.hasCamera { Image(systemName: "video").foregroundColor(.selectedGreen) }
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
                Text(armLabel(state.armMode))
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

// MARK: - Single group view with tabs

struct SingleGroupView: View {
    let group: PanelGroup
    let settings: AppSettings
    let vm: HomeViewModel
    let onBack: () -> Void

    @EnvironmentObject var appState: AppState
    @State private var activeTab: ObjTab = .commands
    @State private var showOutputSheet = false
    @State private var pendingCmd = 0
    @State private var outputNumText = "1"

    enum ObjTab { case commands, events, schedule }

    private func s(_ k: String) -> String { settings.t(k) }

    private var armColor: Color {
        guard let state = group.state else { return .textSecondary }
        switch state.armMode {
        case 1: return .primaryRed
        case 2: return .orange
        default: return .selectedGreen
        }
    }

    private func armLabel(_ mode: Int) -> String {
        switch mode {
        case 0: return s("arm.disarmed")
        case 1: return s("arm.armed")
        case 2: return s("arm.home")
        default: return s("arm.unknown")
        }
    }

    private var commands: [(String, String, Int)] {[
        ("house.fill",            s("cmd.arm_stay"),   55),
        ("lock.open.fill",        s("cmd.disarm"),     53),
        ("lock.fill",             s("cmd.arm"),        52),
        ("sos",                   s("cmd.sos"),        54),
        ("power",                 s("cmd.output"),     43),
        ("arrow.up.right.square", s("cmd.out_status"), 44),
    ]}

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
                HStack(spacing: 0) {
                    if let state = group.state {
                        HStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .foregroundColor(state.hasSignal ? .selectedGreen : .textSecondary)
                            Image(systemName: "bolt")
                                .foregroundColor(state.hasMainPower ? .selectedGreen : .textSecondary)
                            Image(systemName: "battery.100")
                                .foregroundColor(state.hasBattery ? .selectedGreen : .textSecondary)
                            if state.hasWifi { Image(systemName: "wifi").foregroundColor(.selectedGreen) }
                            if state.hasCamera { Image(systemName: "video").foregroundColor(.selectedGreen) }
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
                    if let state = group.state {
                        HStack(spacing: 5) {
                            Image(systemName: state.armMode == 1 ? "lock.fill" : (state.armMode == 2 ? "house.fill" : "lock.open.fill"))
                                .font(.system(size: 12, weight: .semibold))
                            Text(armLabel(state.armMode))
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

            // Tab strip
            HStack(spacing: 0) {
                objTabButton(.commands, icon: "square.grid.2x2", label: s("obj.commands"))
                objTabButton(.events,   icon: "bell",           label: s("obj.events"))
                objTabButton(.schedule, icon: "clock",          label: s("obj.schedule"))
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

            Divider().background(Color.inputBorder).padding(.top, 0)

            // Content
            Group {
                switch activeTab {
                case .commands:
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(commands, id: \.2) { (icon, label, cmd) in
                                CommandGridButton(icon: icon, label: label) {
                                    handleCommand(cmd)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        PanelCamerasSection(panelGroupId: group.id)
                            .environmentObject(settings)
                            .padding(.top, 4)
                    }
                case .events:
                    ObjectEventsView(group: group, settings: settings)
                case .schedule:
                    ObjectScheduleView(group: group, settings: settings)
                }
            }
        }
        .sheet(isPresented: $showOutputSheet) {
            OutputNumberSheet(settings: settings, text: $outputNumText) { num in
                Task { await vm.sendCommand(group: group, cmd: pendingCmd, num: num) }
                showOutputSheet = false
            } onCancel: { showOutputSheet = false }
        }
    }

    @ViewBuilder
    private func objTabButton(_ tab: ObjTab, icon: String, label: String) -> some View {
        let selected = activeTab == tab
        Button { activeTab = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(selected ? .primaryRed : .textSecondary)
            .overlay(alignment: .bottom) {
                if selected {
                    Rectangle()
                        .fill(Color.primaryRed)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func handleCommand(_ cmd: Int) {
        if cmd == 43 || cmd == 44 {
            pendingCmd = cmd
            outputNumText = "1"
            showOutputSheet = true
        } else {
            Task { await vm.sendCommand(group: group, cmd: cmd) }
        }
    }
}

// MARK: - Per-object Events

private enum EventPeriod: CaseIterable {
    case day1, days7, month1, months3, year1

    var hours: Int {
        switch self {
        case .day1:    return 24
        case .days7:   return 168
        case .month1:  return 720
        case .months3: return 2160
        case .year1:   return 8760
        }
    }

    var fromDate: Date { Date().addingTimeInterval(-Double(hours) * 3600) }

    func label(_ s: (String) -> String) -> String {
        switch self {
        case .day1:    return s("period.1d")
        case .days7:   return s("period.7d")
        case .month1:  return s("period.1m")
        case .months3: return s("period.3m")
        case .year1:   return s("period.1y")
        }
    }
}

struct ObjectEventsView: View {
    let group: PanelGroup
    let settings: AppSettings
    @EnvironmentObject var appState: AppState
    @ObservedObject private var cameraStore = CameraStore.shared
    @State private var period: EventPeriod = .day1
    @State private var events: [PanelEvent] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var selectedCamera: Camera?

    private func s(_ k: String) -> String { settings.t(k) }
    private var cameras: [Camera] { cameraStore.cameras(for: group.id) }

    var body: some View {
        VStack(spacing: 0) {
            // Period filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventPeriod.allCases, id: \.hours) { p in
                        let selected = period == p
                        Button { period = p } label: {
                            Text(p.label(s))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selected ? .white : .textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selected ? Color.primaryRed : Color.cardBackground)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(Color.appBackground)

            Divider().background(Color.inputBorder)

            ZStack {
                Color.appBackground.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(.textSecondary)
                } else if let err = loadError {
                    Text(err)
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                        .padding()
                } else if events.isEmpty {
                    Text(s("events.none"))
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(events) { event in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(.textPrimary)
                                        if !event.time.isEmpty {
                                            Text(event.time)
                                                .font(.system(size: 12))
                                                .foregroundColor(.textSecondary)
                                        }
                                    }
                                    Spacer()
                                    if !cameras.isEmpty {
                                        Button { selectedCamera = cameras.first } label: {
                                            VStack(spacing: 2) {
                                                Image(systemName: "video.fill")
                                                    .font(.system(size: 14))
                                                Text(s("events.camera"))
                                                    .font(.system(size: 10))
                                            }
                                            .foregroundColor(.primaryRed)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(Color.primaryRed.opacity(0.1))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                Divider().background(Color.inputBorder).padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedCamera != nil },
            set: { if !$0 { selectedCamera = nil } }
        )) {
            if let cam = selectedCamera { CameraPlayerView(camera: cam) }
        }
        .task(id: period.hours) { await loadEvents() }
    }

    private func loadEvents() async {
        isLoading = true
        loadError = nil
        do {
            events = try await appState.api?.getEvents(
                panel: group.panelId,
                group: group.group,
                fromDate: period.fromDate
            ) ?? []
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Per-object Schedule

struct ObjectScheduleView: View {
    let group: PanelGroup
    let settings: AppSettings
    @ObservedObject private var store = ScheduleStore.shared
    @State private var showAdd = false
    @State private var editing: ScheduleRule?

    private func s(_ k: String) -> String { settings.t(k) }
    private var rules: [ScheduleRule] { store.rules.filter { $0.panelGroupId == group.id } }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(s("schedule.title"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryRed)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                if rules.isEmpty {
                    Spacer()
                    Text(s("schedule.none"))
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(rules) { rule in
                                ScheduleRuleCard(rule: rule, settings: settings) {
                                    editing = rule
                                } onDelete: {
                                    store.delete(id: rule.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            ScheduleEditSheet(settings: settings, existing: nil, panelGroupId: group.id) { rule in
                store.add(rule)
                showAdd = false
            } onCancel: { showAdd = false }
        }
        .sheet(item: $editing) { rule in
            ScheduleEditSheet(settings: settings, existing: rule, panelGroupId: rule.panelGroupId) { updated in
                store.update(updated)
                editing = nil
            } onCancel: { editing = nil }
        }
    }
}

// MARK: - Command grid button

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
    let settings: AppSettings
    @Binding var text: String
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    private func s(_ k: String) -> String { settings.t(k) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Form {
                    Section(s("output.title")) {
                        TextField(s("output.placeholder"), text: $text)
                            .keyboardType(.numberPad)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
            .navigationTitle(s("output.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(s("btn.cancel"), action: onCancel).foregroundColor(.primaryRed)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(s("btn.ok")) { onConfirm(Int(text) ?? 1) }.foregroundColor(.primaryRed)
                }
            }
        }
        .presentationDetents([.height(180)])
    }
}
