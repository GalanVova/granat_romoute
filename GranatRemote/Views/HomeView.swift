import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var groups: [PanelGroup] = []
    @Published var isLoading = true
    @Published var error: String?

    private var client: WampV1Client?
    private var api: LunAPI?

    func load(session: Session) async {
        isLoading = true
        error = nil

        do {
            let uri = URL(string: "ws://\(session.host):\(session.port)/")!
            let c = WampV1Client(uri: uri)
            try await c.connect()

            let a = LunAPI(client: c)
            try await a.signup(login: session.login, password: session.password)

            let g = try await a.getPanelGroups()
            session.groups = g

            self.client = c
            self.api = a
            self.groups = g
            self.isLoading = false
        } catch {
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }

    func sendCommand(group: PanelGroup, cmd: Int, num: Int = 0) async {
        guard let api else { return }
        do {
            try await api.remoteControl(cmd: cmd, panel: group.id, group: group.group, num: num)
        } catch {
            self.error = "Command error: \(error.localizedDescription)"
        }
    }

    func disconnect() {
        Task { await client?.close() }
    }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = HomeViewModel()
    @State private var outputNumText = ""
    @State private var showOutputSheet = false
    @State private var pendingCmd: (PanelGroup, Int)?

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let err = vm.error {
                VStack(spacing: 12) {
                    Text("Connection error\n\(err)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Try again") {
                        guard let sess = appState.session else { return }
                        Task { await vm.load(session: sess) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "222222"))
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.groups) { group in
                            PanelGroupCard(group: group) { cmd, num in
                                if cmd == 43 || cmd == 44 {
                                    pendingCmd = (group, cmd)
                                    outputNumText = "1"
                                    showOutputSheet = true
                                } else {
                                    Task { await vm.sendCommand(group: group, cmd: cmd) }
                                }
                            }
                        }
                    }
                    .padding(12)
                }
            }
        }
        .task {
            guard let sess = appState.session else { return }
            await vm.load(session: sess)
        }
        .onDisappear {
            vm.disconnect()
        }
        .sheet(isPresented: $showOutputSheet) {
            OutputNumberSheet(text: $outputNumText) { num in
                if let (group, cmd) = pendingCmd {
                    Task { await vm.sendCommand(group: group, cmd: cmd, num: num) }
                }
                showOutputSheet = false
            } onCancel: {
                showOutputSheet = false
            }
        }
    }
}

struct PanelGroupCard: View {
    let group: PanelGroup
    let onCommand: (Int, Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("# \(group.id)/\(group.group)")
                .font(.subheadline.weight(.semibold))

            Text(group.name)
                .font(.body)
                .lineLimit(3)

            if let addr = group.address {
                Text(addr)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            FlowLayout(spacing: 8) {
                CommandButton("Arm",     tonal: true)  { onCommand(52, 0) }
                CommandButton("Disarm",  tonal: true)  { onCommand(53, 0) }
                CommandButton("Stay",    tonal: true)  { onCommand(55, 0) }
                CommandButton("SOS",     tonal: true)  { onCommand(54, 0) }
                CommandButton("Output on",  tonal: false) { onCommand(43, 0) }
                CommandButton("Output off", tonal: false) { onCommand(44, 0) }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

struct CommandButton: View {
    let title: String
    let tonal: Bool
    let action: () -> Void

    init(_ title: String, tonal: Bool, action: @escaping () -> Void) {
        self.title = title
        self.tonal = tonal
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(tonal ? Color(hex: "222222").opacity(0.08) : Color.clear)
                .foregroundColor(Color(hex: "222222"))
                .overlay(tonal ? nil : RoundedRectangle(cornerRadius: 8).stroke(Color(hex: "222222"), lineWidth: 1))
                .cornerRadius(8)
        }
    }
}

struct OutputNumberSheet: View {
    @Binding var text: String
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Output number") {
                    TextField("Number", text: $text)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Output number")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        onConfirm(Int(text) ?? 1)
                    }
                }
            }
        }
        .presentationDetents([.height(180)])
    }
}

// Simple flow layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > maxWidth, x > 0 {
                y += rowH + spacing
                x = 0
                rowH = 0
            }
            rowH = max(rowH, s.height)
            x += s.width + spacing
        }
        return CGSize(width: maxWidth, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0
        for sv in subviews {
            let s = sv.sizeThatFits(.unspecified)
            if x + s.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(s))
            rowH = max(rowH, s.height)
            x += s.width + spacing
        }
    }
}
