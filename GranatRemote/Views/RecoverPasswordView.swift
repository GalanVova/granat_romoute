import SwiftUI

struct RecoverPasswordView: View {
    @EnvironmentObject var appState: AppState
    @State private var phone = ""

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

                Text("Recover password")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 16)

                Text("Enter the telephone number associated your account and we will send a SMS with new password.")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                    .padding(.top, 10)

                DarkInputField(text: $phone, placeholder: "+38 (068) 856 37 87", isSecure: false)
                    .keyboardType(.phonePad)
                    .padding(.top, 20)

                Spacer()

                Button {} label: {
                    Text("Send")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(phone.trimmingCharacters(in: .whitespaces).isEmpty ? Color(hex: "1E1E1E") : Color.buttonDark)
                        .foregroundColor(phone.trimmingCharacters(in: .whitespaces).isEmpty ? .textSecondary : .textPrimary)
                        .cornerRadius(10)
                }
                .disabled(phone.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
    }
}
