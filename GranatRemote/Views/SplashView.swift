import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            WelcomeView()
        } else {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                VStack {
                    HStack {
                        GranatLogo()
                            .padding(.leading, 20)
                            .padding(.top, 16)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation { isActive = true }
                }
            }
        }
    }
}

/// Custom GRANAT logo mark (red, top-left)
struct GranatLogo: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primaryRed, lineWidth: 3)
                .frame(width: 36, height: 28)
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.primaryRed, lineWidth: 3)
                .frame(width: 20, height: 14)
                .offset(x: 6, y: 4)
        }
    }
}
