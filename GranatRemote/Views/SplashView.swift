import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            WelcomeView()
        } else {
            ZStack {
                Color(hex: "1C1C1C").ignoresSafeArea()
                VStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Color(hex: "B5161B"))
                    Text("GRANAT")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                        .kerning(2)
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
