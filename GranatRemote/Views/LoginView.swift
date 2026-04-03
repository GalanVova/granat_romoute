import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var login = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var error: String?

    var canLogin: Bool { !login.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Button { appState.goBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textPrimary)
                }
                .padding(.top, 16)

                Text("Login")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 16)

                Text("Now you can enter the login and password received from the SMS.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                    .padding(.top, 10)

                DarkInputField(text: $login, placeholder: "Login", isSecure: false)
                    .padding(.top, 20)

                DarkInputField(
                    text: $password,
                    placeholder: "Password",
                    isSecure: !showPassword,
                    trailingIcon: showPassword ? "eye.slash" : "eye"
                ) { showPassword.toggle() }
                .padding(.top, 12)

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.primaryRed)
                        .padding(.top, 8)
                }

                Spacer()

                Button { handleSignIn() } label: {
                    Text("Log In")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(canLogin ? Color.buttonDark : Color(hex: "1E1E1E"))
                        .foregroundColor(canLogin ? .textPrimary : .textSecondary)
                        .cornerRadius(10)
                }
                .disabled(!canLogin)
                .padding(.bottom, 12)

                Button { appState.navigate(to: .recoverPassword) } label: {
                    Text("Forgot password?")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.clear)
                        .foregroundColor(.textPrimary)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.textPrimary, lineWidth: 1.5))
                }
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            if let li = args.firstIndex(of: "-login"), li + 1 < args.count { login = args[li + 1] }
            if let pi = args.firstIndex(of: "-password"), pi + 1 < args.count { password = args[pi + 1] }
        }
    }

    private func handleSignIn() {
        guard canLogin else { error = "Enter both username and password."; return }
        var pcn = appState.pcn
        if pcn == nil { pcn = demoPCNs.first; if let p = pcn { appState.setPCN(p) } }
        guard let pcn else { error = "Monitoring center is not selected."; return }
        error = nil
        appState.setSession(Session(host: pcn.host, port: pcn.port, login: login, password: password))
        appState.saveCredentials()
        appState.navigate(to: .shell)
    }
}

struct DarkInputField: View {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    var trailingIcon: String? = nil
    var onTrailingTap: (() -> Void)? = nil

    var body: some View {
        HStack {
            if isSecure {
                SecureField("", text: $text)
                    .placeholder(when: text.isEmpty) { Text(placeholder).foregroundColor(.textSecondary) }
                    .foregroundColor(.textPrimary)
            } else {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) { Text(placeholder).foregroundColor(.textSecondary) }
                    .foregroundColor(.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            if let icon = trailingIcon {
                Button { onTrailingTap?() } label: {
                    Image(systemName: icon).foregroundColor(.textSecondary)
                }
            }
        }
        .padding(14)
        .background(Color.inputBackground)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.inputBorder, lineWidth: 1))
        .cornerRadius(8)
    }
}
