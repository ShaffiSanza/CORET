import SwiftUI

struct SplashView: View {
    let onFinished: () -> Void
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "0A0908").ignoresSafeArea()

            VStack(spacing: 12) {
                Text("CORET")
                    .font(.instrumentSerif(42))
                    .foregroundStyle(Color(hex: "C9A96E"))
                    .tracking(4)
                Text("Det siste plagget i outfiten")
                    .font(.dmSans(14))
                    .foregroundStyle(Color(hex: "6B625C"))
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) {
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onFinished()
            }
        }
    }
}
