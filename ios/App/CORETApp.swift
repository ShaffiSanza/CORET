import SwiftUI
import SwiftData

@main
struct CORETApp: App {
    let container: ModelContainer

    init() {
        container = SwiftDataStack.container
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
