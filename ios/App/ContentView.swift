import SwiftUI
import SwiftData
import COREEngine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appTheme") private var themeRaw: String = AppTheme.dark.rawValue
    @State private var selectedTab: Tab = .wardrobe
    @State private var coordinator: EngineCoordinator?
    @State private var wardrobeVM: WardrobeViewModel?
    @State private var studioVM: StudioViewModel?
    @State private var discoverVM: DiscoverViewModel?
    @State private var profileVM: ProfileViewModel?

    enum Tab: String, CaseIterable {
        case wardrobe, studio, discover, profile
    }

    var body: some View {
        Group {
            if coordinator != nil {
                mainContent
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
    private var mainContent: some View {
        let theme = (AppTheme(rawValue: themeRaw) ?? .dark).coreTheme

        ZStack(alignment: .bottom) {
            theme.bg.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .wardrobe:
                    if let vm = wardrobeVM { WardrobeView(viewModel: vm) }
                case .studio:
                    if let vm = studioVM { StudioView(viewModel: vm) }
                case .discover:
                    if let vm = discoverVM { DiscoverView(viewModel: vm) }
                case .profile:
                    if let vm = profileVM { ProfileView(viewModel: vm) }
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
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "DDD6CC").opacity(0.6), lineWidth: 0.5)
                )
                .shadow(color: Color(hex: "392C1E").opacity(0.08), radius: 16, y: 6)
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
                            .fill(Color(hex: "C7A56A").opacity(0.08))
                            .frame(width: 36, height: 36)
                    }
                    Image(systemName: isActive ? "\(icon).fill" : icon)
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(isActive ? Color(hex: "C7A56A") : Color(hex: "746D65").opacity(0.6))
                }
                .frame(height: 36)

                if isActive {
                    Text(label)
                        .font(.dmSans(10, weight: .medium))
                        .foregroundStyle(Color(hex: "C7A56A"))
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
        wardrobeVM = WardrobeViewModel(coordinator: coord)
        studioVM = StudioViewModel(coordinator: coord)
        discoverVM = DiscoverViewModel(coordinator: coord)
        profileVM = ProfileViewModel(coordinator: coord)
        coordinator = coord
    }
}
