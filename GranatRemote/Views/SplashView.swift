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
        HStack(spacing: 8) {
            // Two interlocking L-shapes from Figma SVG
            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                // Original SVG bounding box: x 81.96–112.80, y 104.875–119.926
                // Width: 30.836, Height: 15.051
                func pt(_ x: Double, _ y: Double) -> CGPoint {
                    CGPoint(
                        x: (x - 81.9614) / 30.836 * w,
                        y: (y - 104.875) / 15.051 * h
                    )
                }
                // Path 1: left L-shape (vertical bar left + horizontal bar top)
                var p1 = Path()
                p1.move(to: pt(81.9614, 109.74))
                p1.addLine(to: pt(81.9614, 119.926))
                p1.addLine(to: pt(86.7256, 119.926))
                p1.addLine(to: pt(86.7256, 109.74))
                p1.addLine(to: pt(103.455, 109.74))
                p1.addLine(to: pt(103.455, 104.875))
                p1.addLine(to: pt(86.7256, 104.875))
                p1.closeSubpath()

                // Path 2: right L-shape (vertical bar right + horizontal bar bottom)
                var p2 = Path()
                p2.move(to: pt(112.797, 115.061))
                p2.addLine(to: pt(112.797, 104.875))
                p2.addLine(to: pt(108.033, 104.875))
                p2.addLine(to: pt(108.033, 115.061))
                p2.addLine(to: pt(91.3037, 115.061))
                p2.addLine(to: pt(91.3037, 119.926))
                p2.addLine(to: pt(108.033, 119.926))
                p2.closeSubpath()

                ctx.fill(p1, with: .color(Color(hex: "E00016")))
                ctx.fill(p2, with: .color(Color(hex: "E00016")))
            }
            .frame(width: 31, height: 15)

            Text("GRANAT")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textPrimary)
                .kerning(1)
        }
    }
}
