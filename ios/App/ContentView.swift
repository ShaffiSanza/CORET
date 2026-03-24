import SwiftUI
import SwiftData
import COREEngine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: Tab = .wardrobe
    @State private var coordinator: EngineCoordinator?

    enum Tab: String, CaseIterable {
        case wardrobe, studio, discover, profile
    }

    var body: some View {
        Group {
            if let coordinator {
                mainContent(coordinator: coordinator)
            } else {
                ZStack {
                    Color.coretBgDark.ignoresSafeArea()
                    ProgressView()
                        .tint(Color.coretGoldDark)
                }
                .task { await bootstrap() }
            }
        }
    }

    @ViewBuilder
    private func mainContent(coordinator: EngineCoordinator) -> some View {
        let theme = colorScheme == .dark ? CORETheme.dark : CORETheme.light

        ZStack(alignment: .bottom) {
            theme.bg.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .wardrobe:
                    WardrobeView(viewModel: WardrobeViewModel(coordinator: coordinator))
                case .studio:
                    StudioView(viewModel: StudioViewModel(coordinator: coordinator))
                case .discover:
                    DiscoverView(viewModel: DiscoverViewModel(coordinator: coordinator))
                case .profile:
                    ProfileView(viewModel: ProfileViewModel(coordinator: coordinator))
                }
            }

            floatingNav(theme: theme)
        }
        .environment(\.theme, theme)
    }

    // MARK: - Floating Nav (4 tabs)

    @ViewBuilder
    private func floatingNav(theme: CORETheme) -> some View {
        HStack(spacing: 0) {
            navNode(tab: .wardrobe, icon: "square.grid.2x2", label: "Garderobe", theme: theme)
            navNode(tab: .studio, icon: "star", label: "Studio", theme: theme)
            navNode(tab: .discover, icon: "circle.circle", label: "Oppdage", theme: theme)
            navNode(tab: .profile, icon: "person", label: "Profil", theme: theme)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func navNode(tab: Tab, icon: String, label: String, theme: CORETheme) -> some View {
        let isActive = selectedTab == tab

        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isActive {
                        Circle()
                            .fill(theme.gold.opacity(0.06))
                            .frame(width: 36, height: 36)
                    }
                    Image(systemName: isActive ? "\(icon).fill" : icon)
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(isActive ? theme.gold : theme.text3.opacity(0.75))
                        .shadow(color: isActive ? theme.gold.opacity(0.15) : .clear, radius: 8)
                }
                .frame(height: 36)

                if isActive {
                    Text(label)
                        .font(.dmSans(10, weight: .medium))
                        .foregroundStyle(theme.gold)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(isActive ? 1.05 : 1)
        }
        .accessibilityLabel(label)
    }

    private func bootstrap() async {
        let coord = EngineCoordinator(modelContext: modelContext)
        await coord.recompute()
        coordinator = coord
    }
}
