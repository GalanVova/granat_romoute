import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var login = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var error: String?
    @State private var navigateToShell = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Enter the username and password you received by SMS.")
                .foregroundColor(Color(hex: "6B6B6B"))
                .lineSpacing(5)
                .padding(.top, 16)

            // Login field
            VStack(alignment: .leading, spacing: 6) {
                Text("Username").font(.caption).foregroundColor(.secondary)
                TextField("Enter username", text: $login)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(12)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4)))
            }
            .padding(.top, 16)

            // Password field
            VStack(alignment: .leading, spacing: 6) {
                Text("Password").font(.caption).foregroundColor(.secondary)
                HStack {
                    if showPassword {
                        TextField("Enter password", text: $password)
                    } else {
                        SecureField("Enter password", text: $password)
                    }
                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4)))
            }
            .padding(.top, 12)

            if let error {
                Text(error)
                    .foregroundColor(Color(hex: "B5161B"))
                    .font(.caption)
                    .padding(.top, 8)
            }

            Button {
                handleSignIn()
            } label: {
                Text("Sign in")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "222222"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 16)

            HStack {
                Spacer()
                NavigationLink(destination: RecoverPasswordView()) {
                    Text("Forgot password?")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "222222"))
                }
                Spacer()
            }
            .padding(.top, 10)

            if let country = appState.country, let pcn = appState.pcn {
                Text("Selected: \(country.name) → \(pcn.name)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .padding(.top, 10)
            }

            Spacer()

            NavigationLink(destination: ShellView(), isActive: $navigateToShell) {
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle("Sign in")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func handleSignIn() {
        guard !login.trimmingCharacters(in: .whitespaces).isEmpty, !password.isEmpty else {
            error = "Enter both username and password."
            return
        }
        var pcn = appState.pcn
        if pcn == nil {
            pcn = demoPCNs.first
            if let p = pcn { appState.setPCN(p) }
        }
        guard let pcn else {
            error = "Monitoring center is not selected."
            return
        }
        error = nil
        appState.setSession(Session(host: pcn.host, port: pcn.port, login: login, password: password))
        navigateToShell = true
    }
}
