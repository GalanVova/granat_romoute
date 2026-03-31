import SwiftUI

struct RecoverPasswordView: View {
    @State private var phone = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Enter the phone number linked to your account, and we will send you an SMS with a new password.")
                .foregroundColor(Color(hex: "6B6B6B"))
                .lineSpacing(5)
                .padding(.top, 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("Phone number").font(.caption).foregroundColor(.secondary)
                TextField("+38 (0__) ___ __ __", text: $phone)
                    .keyboardType(.phonePad)
                    .padding(12)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4)))
            }
            .padding(.top, 16)

            Spacer()

            Button {
                // TODO: implement SMS reset
            } label: {
                Text("Send SMS")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(phone.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color(hex: "BDBDBD")
                                : Color(hex: "222222"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(phone.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 16)
        .navigationTitle("Recover password")
        .navigationBarTitleDisplayMode(.inline)
    }
}
