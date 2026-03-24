import SwiftUI
import SwiftData
import COREEngine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Tab = .wardrobe
    @State private var showProfile = false
    @State private var coordinator: EngineCoordinator?

    enum Tab: String {
        case wardrobe, studio, discover
    }

    var body: some View {
        Group {
            if let coordinator {
                mainContent(coordinator: coordinator)
            } else {
                ProgressView()
                    .task { await bootstrap() }
            }
        }
    }

    @ViewBuilder
    private func mainContent(coordinator: EngineCoordinator) -> some View {
        let theme = colorScheme == .dark ? CORETheme.dark : CORETheme.light

        ZStack(alignment: .bottom) {
            theme.bg.ignoresSafeArea()

            TabView(selection: $selectedTab) {
                WardrobeView(viewModel: WardrobeViewModel(coordinator: coordinator))
                    .tag(Tab.wardrobe)

                StudioView(viewModel: StudioViewModel(coordinator: coordinator))
                    .tag(Tab.studio)

                DiscoverView(viewModel: DiscoverViewModel(coordinator: coordinator))
                    .tag(Tab.discover)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom tab bar
            tabBar(theme: theme)
        }
        .environment(\.theme, theme)
        .overlay(alignment: .topTrailing) {
            profileButton(theme: theme)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(viewModel: ProfileViewModel(coordinator: coordinator))
        }
    }

    @ViewBuilder
    private func tabBar(theme: CORETheme) -> some View {
        HStack(spacing: 0) {
            tabItem(tab: .wardrobe, icon: "square.grid.2x2", label: "Garderobe", theme: theme)
            tabItem(tab: .studio, icon: "star", label: "Studio", theme: theme)
            tabItem(tab: .discover, icon: "magnifyingglass", label: "Oppdage", theme: theme)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(theme.border.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal, 60)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func tabItem(tab: Tab, icon: String, label: String, theme: CORETheme) -> some View {
        Button {
            withAnimation(.spring(response: COREDesign.springResponse, dampingFraction: COREDesign.springDamping)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? "\(icon).fill" : icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.dmSans(10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? theme.gold : theme.text3)
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func profileButton(theme: CORETheme) -> some View {
        Button {
            showProfile = true
        } label: {
            Image(systemName: "person.circle")
                .font(.system(size: 24))
                .foregroundStyle(theme.text2)
        }
        .padding(.trailing, COREDesign.horizontalPadding)
        .padding(.top, 8)
    }

    private func bootstrap() async {
        let coord = EngineCoordinator(modelContext: modelContext)
        await coord.recompute()
        coordinator = coord
    }
}
