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

    /// Available garments for each slot (from wardrobe)
    var availableUppers: [Garment] { coordinator.garments().filter { $0.category == .upper } }
    var availableLowers: [Garment] { coordinator.garments().filter { $0.category == .lower } }
    var availableShoes: [Garment] { coordinator.garments().filter { $0.category == .shoes } }
    var availableAccessories: [Garment] { coordinator.garments().filter { $0.category == .accessory } }

    // MARK: - Slot Management

    func setSlot(_ garment: Garment) {
        switch garment.category {
        case .upper:
            // Coats go to outer, others to top
            if garment.baseGroup == .coat || garment.baseGroup == .blazer {
                outerLayer = garment
            } else {
                topLayer = garment
            }
        case .lower:
            bottomLayer = garment
        case .shoes:
            shoes = garment
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
        let best = BestOutfitFinder.findUntriedBest(
            items: all,
            wornOutfits: [],
            profile: profile,
            count: 1
        )
        if let outfit = best.first {
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
        // Log wear for all garments in current outfit
        for garment in currentOutfitGarments {
            await coordinator.logWear(garmentID: garment.id)
        }
    }
}
