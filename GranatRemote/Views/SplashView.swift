import SwiftUI

struct SplashView: View {
    let onDone: () -> Void

    var body: some View {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: onDone)
        }
    }
}

struct GranatLogo: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primaryRed, lineWidth: 3)
                .frame(width: 36, height: 28)
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.primaryRed, lineWidth: 3)
                .frame(width: 20, height: 14)
                .offset(x: 4, y: 4)
        }
    }
}
