import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                // Logo top-left
                GranatLogo()
                    .padding(.top, 8)

                Spacer()

                // Text block in lower third
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hello Friend!")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(.textPrimary)

                    Text("To enter the system, you need to take two simple steps")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 20)

            // Start button pinned to bottom
            VStack {
                Spacer()
                Button {
                    appState.navigate(to: .countrySelect)
                } label: {
                    Text("Start")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(hex: "2C2C2C"))
                        .foregroundColor(.textPrimary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationBarHidden(true)
    }
}
