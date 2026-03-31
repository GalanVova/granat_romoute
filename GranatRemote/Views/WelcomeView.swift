import SwiftUI

struct WelcomeView: View {
    @State private var navigate = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "B5161B"))
                    .padding(.top, 32)

                Spacer()

                Text("Welcome!")
                    .font(.system(size: 34, weight: .bold))

                Text("To get started, complete two quick steps: select your country and choose a monitoring center.")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .lineSpacing(5)
                    .padding(.top, 10)

                Spacer()

                NavigationLink(destination: CountrySelectView()) {
                    Text("Get started")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color(hex: "222222"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .navigationBarHidden(true)
        }
    }
}
