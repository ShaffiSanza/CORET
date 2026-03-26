import Foundation
import Observation
import COREEngine

// MARK: - StudioViewModel
// Manages the flat lay outfit builder.
// Live scoring via DailyOutfitScorer + Fashion Intelligence.
// Accessories via side drawer. Ghost-plagg simulation via ScoreProjector.

@MainActor
@Observable
final class StudioViewModel {

    // MARK: - State

    /// Current outfit slots
    var outerLayer: Garment?
    var topLayer: Garment?
    var bottomLayer: Garment?
    var shoes: Garment?
    var selectedAccessories: [Garment] = []

    /// Live scoring
    var outfitScore: OutfitScore?
    var isDrawerOpen: Bool = false
    var isLoading: Bool = false

    // MARK: - Dependencies
    private let coordinator: EngineCoordinator

    // MARK: - Init
    init(coordinator: EngineCoordinator) {
        self.coordinator = coordinator
    }

    // MARK: - Computed

    var currentOutfitGarments: [Garment] {
        [outerLayer, topLayer, bottomLayer, shoes]
            .compactMap { $0 }
            + selectedAccessories
    }

    var totalStrength: Double { outfitScore?.totalStrength ?? 0 }
    var silhouetteVerdict: String { outfitScore?.silhouetteVerdict ?? "Neutral" }
    var colorVerdict: String { outfitScore?.colorVerdict ?? "Neutral" }
    var archetypeMatch: Archetype { outfitScore?.archetypeMatch ?? .smartCasual }
    var explanation: ExplanationResult? { outfitScore?.explanation }

    /// Score as display int (0-100)
    var scoreDisplay: Int { Int(totalStrength * 100) }

    /// Swipe indices per layer
    var outerIndex: Int = 0
    var topIndex: Int = 0
    var bottomIndex: Int = 0
    var shoesIndex: Int = 0

    /// Available garments for each slot (from wardrobe)
    var availableOuters: [Garment] {
        coordinator.garments().filter { $0.category == .upper && ($0.baseGroup == .coat || $0.baseGroup == .blazer) }
    }
    var availableUppers: [Garment] {
        coordinator.garments().filter { $0.category == .upper && $0.baseGroup != .coat && $0.baseGroup != .blazer }
    }
    var availableLowers: [Garment] { coordinator.garments().filter { $0.category == .lower } }
    var availableShoes: [Garment] { coordinator.garments().filter { $0.category == .shoes } }
    var availableAccessories: [Garment] { coordinator.garments().filter { $0.category == .accessory } }

    // MARK: - Swipe Navigation

    enum Layer { case outer, top, bottom, shoes }

    func swipe(_ layer: Layer, direction: Int) {
        switch layer {
        case .outer:
            let items = availableOuters
            guard !items.isEmpty else { return }
            outerIndex = (outerIndex + direction + items.count) % items.count
            outerLayer = items[outerIndex]
        case .top:
            let items = availableUppers
            guard !items.isEmpty else { return }
            topIndex = (topIndex + direction + items.count) % items.count
            topLayer = items[topIndex]
        case .bottom:
            let items = availableLowers
            guard !items.isEmpty else { return }
            bottomIndex = (bottomIndex + direction + items.count) % items.count
            bottomLayer = items[bottomIndex]
        case .shoes:
            let items = availableShoes
            guard !items.isEmpty else { return }
            shoesIndex = (shoesIndex + direction + items.count) % items.count
            shoes = items[shoesIndex]
        }
        rescore()
    }

    func itemCount(for layer: Layer) -> Int {
        switch layer {
        case .outer: availableOuters.count
        case .top: availableUppers.count
        case .bottom: availableLowers.count
        case .shoes: availableShoes.count
        }
    }

    // MARK: - Slot Management

    func setSlot(_ garment: Garment) {
        switch garment.category {
        case .upper:
            if garment.baseGroup == .coat || garment.baseGroup == .blazer {
                outerLayer = garment
                if let idx = availableOuters.firstIndex(where: { $0.id == garment.id }) { outerIndex = idx }
            } else {
                topLayer = garment
                if let idx = availableUppers.firstIndex(where: { $0.id == garment.id }) { topIndex = idx }
            }
        case .lower:
            bottomLayer = garment
            if let idx = availableLowers.firstIndex(where: { $0.id == garment.id }) { bottomIndex = idx }
        case .shoes:
            shoes = garment
            if let idx = availableShoes.firstIndex(where: { $0.id == garment.id }) { shoesIndex = idx }
        case .accessory:
            toggleAccessory(garment)
        }
        rescore()
    }

    func clearSlot(category: Category) {
        switch category {
        case .upper: topLayer = nil; outerLayer = nil
        case .lower: bottomLayer = nil
        case .shoes: shoes = nil
        case .accessory: selectedAccessories.removeAll()
        }
        rescore()
    }

    func toggleAccessory(_ accessory: Garment) {
        if let idx = selectedAccessories.firstIndex(where: { $0.id == accessory.id }) {
            selectedAccessories.remove(at: idx)
        } else {
            selectedAccessories.append(accessory)
        }
        rescore()
    }

    // MARK: - Scoring

    func rescore() {
        let garments = currentOutfitGarments
        guard !garments.isEmpty else {
            outfitScore = nil
            return
        }
        outfitScore = DailyOutfitScorer.scoreOutfit(
            garments: garments,
            profile: coordinator.profile()
        )
    }

    // MARK: - Surprise

    func generateSurpriseOutfit() {
        let profile = coordinator.profile()
        let all = coordinator.garments()

        // Exclude current outfit and require top + bottom + shoes
        let currentIDs = Set(currentOutfitGarments.map(\.id))
        let best = BestOutfitFinder.findBest(
            items: all,
            profile: profile,
            count: 20
        ).filter { outfit in
            let categories = Set(outfit.garments.map(\.category))
            let hasTop = outfit.garments.contains { $0.category == .upper && $0.baseGroup != .coat && $0.baseGroup != .blazer }
            let hasBottom = categories.contains(.lower)
            let hasShoes = categories.contains(.shoes)
            let isDifferent = Set(outfit.garments.map(\.id)) != currentIDs
            return hasTop && hasBottom && hasShoes && isDifferent
        }

        // Pick a random one from top results
        if let outfit = best.randomElement() {
            // Assign to slots
            outerLayer = nil
            topLayer = nil
            bottomLayer = nil
            shoes = nil
            selectedAccessories = []

            for garment in outfit.garments {
                switch garment.category {
                case .upper:
                    if garment.baseGroup == .coat || garment.baseGroup == .blazer {
                        outerLayer = garment
                    } else {
                        topLayer = garment
                    }
                case .lower: bottomLayer = garment
                case .shoes: shoes = garment
                case .accessory: selectedAccessories.append(garment)
                }
            }
            rescore()
        }
    }

    // MARK: - Save

    func wearToday() async {
        for garment in currentOutfitGarments {
            await coordinator.logWear(garmentID: garment.id)
        }
    }

    // MARK: - Test Outfits (Phase 5 validation)

    /// Three fixed test outfits for validating Studio rendering.
    /// Cycles through: dark tee + denim + sneaker, knit + trousers + loafer,
    /// jacket + pants + boot.
    var testOutfitIndex: Int = 0

    func loadTestOutfit(_ index: Int) {
        let all = coordinator.garments()
        outerLayer = nil
        topLayer = nil
        bottomLayer = nil
        shoes = nil
        selectedAccessories = []

        func find(_ cat: Category, _ bg: BaseGroup) -> Garment? {
            all.first { $0.category == cat && $0.baseGroup == bg }
        }

        switch index % 3 {
        case 0: // dark tee + denim + sneaker
            topLayer = find(.upper, .tee)
            bottomLayer = find(.lower, .jeans)
            shoes = find(.shoes, .sneakers)
        case 1: // knit + trousers + loafer
            topLayer = find(.upper, .knit)
            bottomLayer = find(.lower, .trousers)
            shoes = find(.shoes, .loafers)
        case 2: // jacket + pants + boot
            outerLayer = find(.upper, .coat)
            topLayer = find(.upper, .shirt)
            bottomLayer = find(.lower, .chinos)
            shoes = find(.shoes, .boots)
        default: break
        }
        rescore()
    }
}
