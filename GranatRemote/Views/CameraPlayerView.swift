import SwiftUI
import AVKit

// MARK: - Camera Player (AVKit)

struct CameraPlayerView: View {
    let camera: Camera
    @State private var player: AVPlayer?
    @State private var showError = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView().tint(.white)
            }
        }
        .onAppear {
            guard let url = URL(string: camera.url) else { showError = true; return }
            player = AVPlayer(url: url)
            player?.play()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .alert("Cannot open stream", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(camera.url)
        }
        .navigationTitle(camera.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Camera row in list

struct CameraRow: View {
    let camera: Camera
    let onDelete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "video.fill")
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(camera.name)
                    .font(.system(size: 15))
                    .foregroundColor(.textPrimary)
                Text(camera.url)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.primaryRed)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Add / Edit camera sheet

struct CameraEditSheet: View {
    let settings: AppSettings
    var existing: Camera?
    let panelGroupId: String?
    let onSave: (Camera) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var url: String

    private func s(_ k: String) -> String { settings.t(k) }

    init(settings: AppSettings, existing: Camera? = nil, panelGroupId: String? = nil,
         onSave: @escaping (Camera) -> Void, onCancel: @escaping () -> Void) {
        self.settings     = settings
        self.existing     = existing
        self.panelGroupId = panelGroupId
        self.onSave       = onSave
        self.onCancel     = onCancel
        _name = State(initialValue: existing?.name ?? "")
        _url  = State(initialValue: existing?.url  ?? "rtsp://")
    }

    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && !url.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Form {
                    Section(s("camera.name")) {
                        TextField(s("camera.name_ph"), text: $name)
                            .foregroundColor(.textPrimary)
                            .autocapitalization(.sentences)
                            .disableAutocorrection(true)
                    }
                    Section(s("camera.url")) {
                        TextField(s("camera.url_ph"), text: $url)
                            .foregroundColor(.textPrimary)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
            }
            .navigationTitle(existing == nil ? s("camera.add") : s("camera.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(s("btn.cancel"), action: onCancel).foregroundColor(.primaryRed)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(s("btn.save")) {
                        var cam = existing ?? Camera(name: "", url: "")
                        cam.name = name.trimmingCharacters(in: .whitespaces)
                        cam.url  = url.trimmingCharacters(in: .whitespaces)
                        cam.panelGroupId = panelGroupId
                        onSave(cam)
                    }
                    .disabled(!canSave)
                    .foregroundColor(canSave ? .primaryRed : .textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
