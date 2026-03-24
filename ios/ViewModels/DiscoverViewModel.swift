import Foundation
import Observation
import COREEngine

// MARK: - DiscoverViewModel
// Manages the Discover feed (70/30 + Full modes).
// Handles swipe actions, bookmarks, missing piece display.
// Talks to backend API for feed data.
//
// Feed modes:
//   70/30: owned-owned-owned-rotation rhythm, ghost at pos 4,9,14,19
//   Full:  brand grid → brand-filtered feed (100% ghost)

@MainActor
@Observable
final class DiscoverViewModel {

    // MARK: - State

    /// Current feed cards
    var cards: [DiscoverCard] = []
    var currentIndex: Int = 0
    var mode: DiscoverMode = .seventyThirty
    var isLoading: Bool = false
    var isEndOfFeed: Bool = false

    /// Brand grid (Full mode landing)
    var brands: [BrandCard] = []
    var selectedBrandID: String?

    /// Feed metadata
    var clarityEstimate: Int = 0
    var gapsDetected: Int = 0
    var needsOnboarding: Bool = false

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    var currentCard: DiscoverCard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var hasCards: Bool { !cards.isEmpty && currentIndex < cards.count }

    // MARK: - Feed Loading

    /// Load feed from backend API
    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Replace with actual API call when backend is deployed
        // GET /api/discover/feed?mode=7030|full&brand_id=X
        // For now: generate locally using engine
        let profile = coordinator.profile()
        let garments = coordinator.garments()

        guard !garments.isEmpty else {
            cards = []
            isEndOfFeed = true
            return
        }

        let all = BestOutfitFinder.findBest(items: garments, profile: profile, count: 20)
        cards = all.enumerated().map { index, outfit in
            let score = DailyOutfitScorer.scoreOutfit(garments: outfit.garments, profile: profile)
            return DiscoverCard(
                garments: outfit.garments,
                outfitName: outfit.label,
                strength: outfit.strength,
                score: score,
                feedType: index % 4 == 3 ? .rotation : .owned,
                missingPiece: nil
            )
        }
        currentIndex = 0
        isEndOfFeed = cards.isEmpty
    }

    /// Load brand grid for Full mode
    func loadBrands() async {
        isLoading = true
        defer { isLoading = false }
        // TODO: GET /api/discover/brands
    }

    // MARK: - Swipe Actions

    func swipeUp() {
        // Next card
        guard currentIndex < cards.count - 1 else {
            isEndOfFeed = true
            return
        }
        currentIndex += 1
    }

    func like() {
        guard let card = currentCard else { return }
        // TODO: POST /api/discover/action {action: "like", card_id: ...}
        swipeUp()
    }

    func pass() {
        guard let card = currentCard else { return }
        // TODO: POST /api/discover/action {action: "pass", card_id: ...}
        swipeUp()
    }

    func hook() {
        guard let card = currentCard else { return }
        // TODO: POST /api/discover/action {action: "hook", card_id: ..., garment_ids: ...}
        // Hook auto-bookmarks on backend
        swipeUp()
    }

    // MARK: - Mode

    func switchMode(_ newMode: DiscoverMode) {
        mode = newMode
        currentIndex = 0
        cards = []
        Task { await loadFeed() }
    }

    func selectBrand(_ brandID: String) {
        selectedBrandID = brandID
        Task { await loadFeed() }
    }
}

// MARK: - Supporting Types

enum DiscoverMode: String {
    case seventyThirty = "7030"
    case full = "full"
}

/// Local DiscoverCard (before backend API is connected)
struct DiscoverCard: Identifiable {
    let id = UUID()
    let garments: [Garment]
    let outfitName: String
    let strength: Double
    let score: OutfitScore
    let feedType: FeedType
    let missingPiece: MissingPieceLocal?

    enum FeedType { case owned, rotation, ghost }
}

struct MissingPieceLocal {
    let name: String
    let brand: String
    let baseGroup: String
    let gapType: String
    let shopURL: URL?
}

struct BrandCard: Identifiable {
    let id: String
    let name: String
    let archetype: String
    let productCount: Int
    let coverImage: URL?
    let styleTags: [String]
}
