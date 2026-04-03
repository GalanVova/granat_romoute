import SwiftUI

// MARK: - Settings root

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject var cameraStore = CameraStore.shared
    @State private var showAddCamera = false
    @State private var editingCamera: Camera?
    @State private var showLogoutAlert = false
    @State private var showSchedule = false

    private func s(_ key: String) -> String { appSettings.t(key) }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                        Text(s("settings.title"))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            .padding(.bottom, 16)

                        // MARK: Account
                        sectionHeader(s("settings.account"))
                        VStack(spacing: 0) {
                            if let session = appState.session {
                                settingsRow(label: s("settings.login"), value: session.login)
                                Divider().background(Color.inputBorder).padding(.leading, 16)
                                if let pcn = appState.pcn {
                                    settingsRow(label: s("settings.pcn"), value: pcn.name)
                                    Divider().background(Color.inputBorder).padding(.leading, 16)
                                }
                            }
                            Button { showLogoutAlert = true } label: {
                                HStack {
                                    Text(s("settings.logout"))
                                        .font(.system(size: 15))
                                        .foregroundColor(.primaryRed)
                                    Spacer()
                                    Image(systemName: "arrow.right.square")
                                        .foregroundColor(.primaryRed)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: Appearance
                        sectionHeader(s("settings.appearance"))
                        VStack(spacing: 0) {
                            // Theme picker
                            HStack {
                                Text(s("settings.appearance"))
                                    .font(.system(size: 15))
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Picker("", selection: $appSettings.theme) {
                                    ForEach(AppTheme.allCases, id: \.self) { th in
                                        Text(themeLabel(th)).tag(th)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.primaryRed)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            Divider().background(Color.inputBorder).padding(.leading, 16)

                            // Language picker
                            HStack {
                                Text(s("settings.language"))
                                    .font(.system(size: 15))
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Picker("", selection: $appSettings.language) {
                                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                                        Text(lang.displayName).tag(lang)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.primaryRed)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: Schedule
                        sectionHeader(s("schedule.title"))
                        VStack(spacing: 0) {
                            NavigationLink {
                                ScheduleView()
                                    .environmentObject(appSettings)
                            } label: {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 15))
                                        .foregroundColor(.primaryRed)
                                        .frame(width: 28)
                                    Text(s("schedule.title"))
                                        .font(.system(size: 15))
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    let count = ScheduleStore.shared.rules.count
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.textSecondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: Cameras
                        sectionHeader(s("settings.cameras"))
                        VStack(spacing: 0) {
                            ForEach(cameraStore.cameras) { cam in
                                CameraRow(camera: cam) {
                                    cameraStore.delete(id: cam.id)
                                } onEdit: {
                                    editingCamera = cam
                                }
                                if cam.id != cameraStore.cameras.last?.id {
                                    Divider().background(Color.inputBorder).padding(.leading, 56)
                                }
                            }
                            if !cameraStore.cameras.isEmpty {
                                Divider().background(Color.inputBorder).padding(.leading, 16)
                            }
                            Button { showAddCamera = true } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.primaryRed)
                                    Text(s("settings.add_camera"))
                                        .font(.system(size: 15))
                                        .foregroundColor(.primaryRed)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)

                        // MARK: About
                        sectionHeader(s("settings.about"))
                        VStack(spacing: 0) {
                            settingsRow(label: s("settings.version"), value: appVersion())
                        }
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        .sheet(isPresented: $showAddCamera) {
            CameraEditSheet(settings: appSettings, panelGroupId: nil) { cam in
                cameraStore.add(cam)
                showAddCamera = false
            } onCancel: { showAddCamera = false }
        }
        .sheet(item: $editingCamera) { cam in
            CameraEditSheet(settings: appSettings, existing: cam, panelGroupId: cam.panelGroupId) { updated in
                cameraStore.update(updated)
                editingCamera = nil
            } onCancel: { editingCamera = nil }
        }
        .alert(s("settings.logout_title"), isPresented: $showLogoutAlert) {
            Button(s("settings.logout"), role: .destructive) {
                appState.clearSavedCredentials()
                appState.logout()
            }
            Button(s("btn.cancel"), role: .cancel) {}
        } message: {
            Text(s("settings.logout_msg"))
        }
    }

    // MARK: Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
    }

    private func settingsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func themeLabel(_ theme: AppTheme) -> String {
        switch theme {
        case .dark:   return s("theme.dark")
        case .light:  return s("theme.light")
        case .system: return s("theme.system")
        }
    }

    private func appVersion() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

// MARK: - Panel-scoped camera list (inside SingleGroupView)

struct PanelCamerasSection: View {
    let panelGroupId: String
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject var cameraStore = CameraStore.shared
    @State private var showAdd = false
    @State private var editingCamera: Camera?
    @State private var selectedCamera: Camera?

    private func s(_ k: String) -> String { appSettings.t(k) }
    var cams: [Camera] { cameraStore.cameras(for: panelGroupId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(s("panel.cameras"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primaryRed)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if cams.isEmpty {
                Text(s("panel.no_cameras"))
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            } else {
                VStack(spacing: 0) {
                    ForEach(cams) { cam in
                        Button { selectedCamera = cam } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cam.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.textPrimary)
                                    Text(cam.url)
                                        .font(.system(size: 11))
                                        .foregroundColor(.textSecondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if cam.id != cams.last?.id {
                            Divider().background(Color.inputBorder).padding(.leading, 52)
                        }
                    }
                }
                .background(Color.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .sheet(isPresented: $showAdd) {
            CameraEditSheet(settings: appSettings, panelGroupId: panelGroupId) { cam in
                cameraStore.add(cam)
                showAdd = false
            } onCancel: { showAdd = false }
        }
        .sheet(item: $editingCamera) { cam in
            CameraEditSheet(settings: appSettings, existing: cam, panelGroupId: cam.panelGroupId) { updated in
                cameraStore.update(updated)
                editingCamera = nil
            } onCancel: { editingCamera = nil }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedCamera != nil },
            set: { if !$0 { selectedCamera = nil } }
        )) {
            if let cam = selectedCamera { CameraPlayerView(camera: cam) }
        }
    }
}
