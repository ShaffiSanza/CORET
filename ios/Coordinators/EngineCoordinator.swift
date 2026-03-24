import Foundation
import SwiftData
import COREEngine

// MARK: - EngineCoordinator
// The single bridge between SwiftData (persistence) and V2 engines (computation).
// All engine interaction flows through here — ViewModels never call engines directly.
//
// Architectural invariants:
//   1. Fetch entities → convert to domain types → run engines → return results
//   2. Engines never mutate SwiftData. EngineCoordinator does.
//   3. No parallel recomputes. isComputing guard enforces this.
//   4. All published state updated on MainActor after background computation.

@MainActor
final class EngineCoordinator: ObservableObject {

    // MARK: - Dependencies
    private let modelContext: ModelContext

    // MARK: - Published State (observed by ViewModels)
    private(set) var latestClarity: ClaritySnapshot?
    private(set) var latestGapResult: GapResult?
    private(set) var latestIdentity: WardrobeIdentity?
    private(set) var latestJourney: JourneySnapshot?
    private(set) var latestMomentum: JourneyMomentum?
    private(set) var latestMilestones: [Milestone] = []
    private(set) var isComputing: Bool = false

    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recompute (Primary Entry Point)

    /// Full engine recompute. Must be called after any structural mutation.
    /// Guards against concurrent runs. Heavy work dispatched to background.
    func recompute() async {
        guard !isComputing else { return }
        isComputing = true
        defer { isComputing = false }

        var garments = fetchGarments()
        let profile = fetchOrCreateProfile()

        // Seed mock data on first launch (empty wardrobe)
        #if DEBUG
        if garments.isEmpty {
            let mocks = MockData.seedGarments()
            for garment in mocks {
                let entity = GarmentEntity.from(garment)
                modelContext.insert(entity)
            }
            try? modelContext.save()
            garments = fetchGarments()
        }
        #endif

        // Dispatch heavy computation to background cooperative thread
        let result = await Task.detached(priority: .userInitiated) {
            let clarity = ClarityEngine.compute(items: garments, profile: profile)
            let gaps = OptimizeEngineV2.analyze(items: garments, profile: profile)
            let identity = IdentityResolver.resolve(items: garments, profile: profile)
            return (clarity, gaps, identity)
        }.value

        let (clarity, gaps, identity) = result

        // Update cache
        updateCache(clarity: clarity, gaps: gaps)

        // Persist snapshot if threshold met
        let lastEntity = fetchLastSnapshot()
        if ClaritySnapshotEntity.shouldPersist(newSnapshot: clarity, lastStored: lastEntity) {
            if let entity = ClaritySnapshotEntity.from(clarity) {
                modelContext.insert(entity)
                try? modelContext.save()
            }
        }

        // Recompute journey from full history
        let history = fetchClarityHistory()
        let journey = MilestoneTracker.evaluate(history: history)
        let momentum = MilestoneTracker.momentum(history: history)
        let allMilestones = MilestoneTracker.milestones(history: history)
        persistNewMilestones(allMilestones, history: history)

        // Update key garment flags on entities
        let keyIDs = Set(KeyGarmentResolver.keyGarmentIDs(items: garments, profile: profile))
        updateKeyGarmentFlags(keyIDs: keyIDs)

        // Publish results on MainActor (already on MainActor)
        latestClarity = clarity
        latestGapResult = gaps
        latestIdentity = identity
        latestJourney = journey
        latestMomentum = momentum
        latestMilestones = allMilestones
    }

    // MARK: - Garment CRUD

    func addGarment(_ garment: Garment) async {
        let entity = GarmentEntity.from(garment)
        modelContext.insert(entity)
        invalidateCache()
        try? modelContext.save()
        await recompute()
    }

    func removeGarment(id: UUID) async {
        guard let entity = fetchGarmentEntity(id: id) else { return }
        modelContext.delete(entity)
        invalidateCache()
        try? modelContext.save()
        await recompute()
    }

    func updateGarment(_ garment: Garment) async {
        guard let entity = fetchGarmentEntity(id: garment.id) else { return }
        entity.apply(garment)
        invalidateCache()
        try? modelContext.save()
        await recompute()
    }

    // MARK: - Profile Mutations

    func updateArchetype(_ archetype: Archetype) async {
        let profile = fetchOrCreateProfileEntity()
        profile.primaryArchetype = archetype.rawValue
        invalidateCache()
        try? modelContext.save()
        await recompute()
    }

    func updateLocation(latitude: Double, longitude: Double) async {
        let profile = fetchOrCreateProfileEntity()
        profile.latitude = latitude
        profile.longitude = longitude
        try? modelContext.save()
        // Location change doesn't affect cohesion scores, only seasonal weights.
        // Recompute optional — caller may explicitly trigger via applyRecalibration.
    }

    func applyRecalibration(season: Season) async {
        let profile = fetchOrCreateProfileEntity()
        profile.lastRecalibrationDate = Date()
        invalidateCache()
        try? modelContext.save()
        await recompute()
    }

    func resetProfile() async {
        // Delete all data then create fresh profile
        deleteAllGarments()
        deleteAllSnapshots()
        deleteAllMilestones()
        deleteCache()
        deleteProfileEntity()
        _ = fetchOrCreateProfileEntity()
        try? modelContext.save()

        // Reset published state
        latestClarity = nil
        latestGapResult = nil
        latestIdentity = nil
        latestJourney = nil
        latestMomentum = nil
        latestMilestones = []

        // Re-seed mock data and recompute
        await recompute()
    }

    // MARK: - What-If Simulation (no persistence side effects)

    func projectAdding(_ garment: Garment) -> ProjectionResult {
        let garments = fetchGarments()
        let profile = fetchOrCreateProfile()
        return ScoreProjector.project(adding: garment, to: garments, profile: profile)
    }

    func projectRemoving(_ garment: Garment) -> ProjectionResult {
        let garments = fetchGarments()
        let profile = fetchOrCreateProfile()
        return ScoreProjector.reverseProject(removing: garment, from: garments, profile: profile)
    }

    // MARK: - Accessors

    func garments() -> [Garment] { fetchGarments() }
    func garmentEntities() -> [GarmentEntity] { fetchGarmentEntities() }
    func profile() -> UserProfile { fetchOrCreateProfile() }
    func clarityHistory() -> [ClaritySnapshot] { fetchClarityHistory() }
    func milestones() -> [Milestone] { latestMilestones }

    func bestOutfit() -> RankedOutfit? {
        let garments = fetchGarments()
        guard !garments.isEmpty else { return nil }
        let profile = fetchOrCreateProfile()
        return BestOutfitFinder.findBest(items: garments, profile: profile, count: 1).first
    }

    func primaryGap() -> StructuralGap? {
        latestGapResult?.gaps.first
    }

    func logWear(garmentID: UUID) async {
        // Persistence for wear logs — lightweight, no full recompute
        // TODO: persist WearLog to SwiftData when WearLogEntity is added
    }

    func seasonalRecommendation() -> SeasonalRecommendationV2? {
        let profileEntity = fetchOrCreateProfileEntity()
        guard let lat = profileEntity.latitude, let _ = profileEntity.longitude else { return nil }
        let profile = profileEntity.toProfile()
        let garments = fetchGarments()
        let coverage = SeasonalEngineV2.coverage(items: garments)
        let currentSeason = coverage.weakestSeason   // Use weakest as proxy for current context
        let month = Calendar.current.component(.month, from: Date())
        return SeasonalEngineV2.recommend(latitude: lat, month: month, currentSeason: currentSeason)
    }

    // MARK: - Private: Fetch Helpers

    private func fetchGarments() -> [Garment] {
        fetchGarmentEntities().map { $0.toGarment() }
    }

    private func fetchGarmentEntities() -> [GarmentEntity] {
        let descriptor = FetchDescriptor<GarmentEntity>(
            sortBy: [SortDescriptor(\.dateAdded)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchGarmentEntity(id: UUID) -> GarmentEntity? {
        let descriptor = FetchDescriptor<GarmentEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchOrCreateProfile() -> UserProfile {
        fetchOrCreateProfileEntity().toProfile()
    }

    private func fetchOrCreateProfileEntity() -> UserProfileEntity {
        let descriptor = FetchDescriptor<UserProfileEntity>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let new = UserProfileEntity()
        modelContext.insert(new)
        try? modelContext.save()
        return new
    }

    private func deleteProfileEntity() {
        let descriptor = FetchDescriptor<UserProfileEntity>()
        if let entity = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entity)
        }
    }

    private func fetchLastSnapshot() -> ClaritySnapshotEntity? {
        var descriptor = FetchDescriptor<ClaritySnapshotEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchClarityHistory() -> [ClaritySnapshot] {
        let descriptor = FetchDescriptor<ClaritySnapshotEntity>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let entities = (try? modelContext.fetch(descriptor)) ?? []
        return entities.compactMap { $0.decode() }
    }

    // MARK: - Private: Cache

    private func fetchOrCreateCache() -> EngineCacheEntity {
        let descriptor = FetchDescriptor<EngineCacheEntity>()
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let new = EngineCacheEntity()
        modelContext.insert(new)
        return new
    }

    private func updateCache(clarity: ClaritySnapshot, gaps: GapResult) {
        let cache = fetchOrCreateCache()
        cache.update(clarity: clarity, gaps: gaps)
        try? modelContext.save()
    }

    private func invalidateCache() {
        let descriptor = FetchDescriptor<EngineCacheEntity>()
        if let cache = try? modelContext.fetch(descriptor).first {
            cache.invalidate()
        }
    }

    private func deleteCache() {
        let descriptor = FetchDescriptor<EngineCacheEntity>()
        if let cache = try? modelContext.fetch(descriptor).first {
            modelContext.delete(cache)
        }
    }

    // MARK: - Private: Milestone Persistence

    private func persistNewMilestones(_ all: [Milestone], history: [ClaritySnapshot]) {
        let storedDescriptor = FetchDescriptor<MilestoneEntity>()
        let stored = (try? modelContext.fetch(storedDescriptor)) ?? []
        let storedKeys = Set(stored.map { "\($0.type)-\($0.snapshotIndex)" })

        for milestone in all {
            let key = "\(milestone.type.rawValue)-\(milestone.snapshotIndex)"
            if !storedKeys.contains(key) {
                let entity = MilestoneEntity.from(milestone)
                modelContext.insert(entity)
            }
        }
        try? modelContext.save()
    }

    // MARK: - Private: Key Garment Flag Sync

    private func updateKeyGarmentFlags(keyIDs: Set<UUID>) {
        let entities = fetchGarmentEntities()
        for entity in entities {
            let shouldBeKey = keyIDs.contains(entity.id)
            if entity.isKeyGarment != shouldBeKey {
                entity.isKeyGarment = shouldBeKey
            }
        }
        try? modelContext.save()
    }

    // MARK: - Private: Bulk Delete

    private func deleteAllGarments() {
        let descriptor = FetchDescriptor<GarmentEntity>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        all.forEach { modelContext.delete($0) }
    }

    private func deleteAllSnapshots() {
        let descriptor = FetchDescriptor<ClaritySnapshotEntity>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        all.forEach { modelContext.delete($0) }
    }

    private func deleteAllMilestones() {
        let descriptor = FetchDescriptor<MilestoneEntity>()
        let all = (try? modelContext.fetch(descriptor)) ?? []
        all.forEach { modelContext.delete($0) }
    }
}
