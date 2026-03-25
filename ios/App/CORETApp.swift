import SwiftUI
import SwiftData

@main
struct CORETApp: App {
    let container: ModelContainer
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.dark.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    init() {
        container = SwiftDataStack.container
    }

    private var appTheme: AppTheme {
        AppTheme(rawValue: themeRaw) ?? .dark
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showSplash = false
                        }
                    }
                } else if !hasCompletedOnboarding {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            hasCompletedOnboarding = true
                        }
                    }
                } else {
                    ContentView()
                }
            }
            .preferredColorScheme(appTheme.colorScheme)
        }
        .modelContainer(container)
    }
}
