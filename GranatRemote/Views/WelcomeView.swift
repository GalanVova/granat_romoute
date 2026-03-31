import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    GranatLogo()
                        .padding(.top, 16)

                    Spacer()

                    Text("Hello Friend!")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("To enter the system, you need to take two simple steps")
                        .font(.system(size: 15))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                        .padding(.top, 12)

                    Spacer()

                    NavigationLink(destination: CountrySelectView()) {
                        Text("Start")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.buttonDark)
                            .foregroundColor(.textPrimary)
                            .cornerRadius(10)
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
}
